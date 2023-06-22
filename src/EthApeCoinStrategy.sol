// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {ISwapRouter} from "./Uniswap/ISwapRouter.sol";
import {Config} from "./Config.sol";
import {IPriceOracle} from "./IPriceOracle.sol";
import "forge-std/console.sol";
// Precision for price in USD is 1e8

contract EthApeCoinStrategy is Owned, ERC20("EACS", "EACS", 18), Config {
    uint256 public constant PRECISION = 1e18;
    uint24 public constant POOL_FEE = 3000;

    enum BorrowRate {
        INVALID,
        STABLE,
        VARIABLE
    }

    uint256 public withdrawPool;
    IPriceOracle public oracle;
    uint248 public agreementID;

    constructor(address _owner, address _oracle) Owned(_owner) {
        oracle = IPriceOracle(_oracle);
    }

    function getPositions() public view returns (uint256 _aEthWethColl, uint256 _aVariableDebtUSDC, uint256 _apeBal) {
        _aEthWethColl = AAVE_ETH_WETH.balanceOf(address(this));
        _aVariableDebtUSDC = AAVE_VARIABLE_DEBT_USDC.balanceOf(address(this));
        _apeBal = PC_APE.balanceOf(address(this));
    }

    function getPrice(address _asset) public view returns (uint256) {
        return oracle.getAssetPrice(_asset); // Precision of 1e8
    }

    function getNetAsset()
        public
        view
        returns (uint256 _apeUSD, uint256 _usdcDebtUSD, uint256 _ethCollUSD, uint256 _netUSDAmt)
    {
        (uint256 _aEthWethColl, uint256 _aVariableDebtUSDC, uint256 _apeBal) = getPositions();
        _apeUSD = getPrice(APE_COIN_ADDRESS) * _apeBal / 1e8;
        _usdcDebtUSD = (getPrice(USDC_ADDRESS) * _aVariableDebtUSDC * 1e18) / (1e8 * 1e6);
        _ethCollUSD = getPrice(WETH_ADDRESS) * _aEthWethColl / 1e8;
        _netUSDAmt = _apeUSD + _ethCollUSD - _usdcDebtUSD;
    }

    function setOracle(address _oracle) public {
        oracle = IPriceOracle(_oracle);
    }

    function getShareForUSD(uint256 _amtUSD) public view returns (uint256) {
        (,,, uint256 _netUSDAmt) = getNetAsset();
        return (_amtUSD * totalSupply) / _netUSDAmt;
    }

    function getShareForEth(uint256 _amtEth) public view returns (uint256) {
        (,,, uint256 _netUSDAmt) = getNetAsset();
        uint256 _ethAmtUSD = (getPrice(WETH_ADDRESS) * _amtEth) / 1e8;
        return (_ethAmtUSD * totalSupply) / _netUSDAmt;
    }

    function getEthForShare(uint256 _amtShare) public view returns (uint256) {
        (,,, uint256 _netUSDAmt) = getNetAsset();
        uint256 _userShareInUSD = (_amtShare * _netUSDAmt) / totalSupply;
        return (_userShareInUSD * 1e8) / getPrice(WETH_ADDRESS);
    }

    function approveToken(ERC20 _token, address _spender, uint256 _amt) external onlyOwner {
        _token.approve(_spender, _amt);
    }

    function deposit(address _to) external payable {
        console.log("Depositing: ", msg.value, "Eth for", _to);
        WETH.deposit{value: msg.value}();
        if (totalSupply == 0) {
            _mint(_to, msg.value);
        } else {
            uint256 _shares = getShareForEth(msg.value);
            _mint(_to, _shares);
        }
        AAVE_POOL.supply(WETH_ADDRESS, msg.value, address(this), 0);
    }

    function withdraw(uint256 _amtShare, address _to) external {
        require(balanceOf[msg.sender] > _amtShare, "Insufficient Balance");
        uint256 _ethAmt = getEthForShare(_amtShare);
        require(_ethAmt <= withdrawPool, "NA");
        AAVE_POOL.withdraw(WETH_ADDRESS, _ethAmt, _to);
    }

    function repayToAAVE(uint256 _amt) external payable onlyOwner {
        USDC.approve(address(AAVE_POOL), type(uint256).max);
        AAVE_POOL.repay(USDC_ADDRESS, _amt, uint256(BorrowRate.VARIABLE), address(this));
    }

    function borrowFromAAVE(uint256 _amount) public onlyOwner {
        console.log("Borrowing", _amount, " USDC from AAVE");
        AAVE_POOL.borrow(USDC_ADDRESS, _amount, uint256(BorrowRate.VARIABLE), 0, address(this));
    }

    function swapUSDCForApe(uint256 _amt) public onlyOwner returns (uint256) {
        USDC.approve(SWAP_ROUTER_ADDRESS, _amt);
        //
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: USDC_ADDRESS,
            tokenOut: APE_COIN_ADDRESS,
            fee: POOL_FEE,
            recipient: address(this),
            deadline: block.timestamp + 12,
            amountIn: _amt,
            amountOutMinimum: 0, // Not Good
            sqrtPriceLimitX96: 0
        });
        //
        uint256 _ret = SWAP_ROUTER.exactInputSingle(params);
        return _ret;
    }

    function swapApeForUSDC(uint256 _amt) public onlyOwner returns (uint256) {
        APE.approve(SWAP_ROUTER_ADDRESS, _amt);
        //
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: APE_COIN_ADDRESS,
            tokenOut: USDC_ADDRESS,
            fee: POOL_FEE,
            recipient: address(this),
            deadline: block.timestamp + 12,
            amountIn: _amt,
            amountOutMinimum: 0, // Not Good
            sqrtPriceLimitX96: 0
        });
        //
        return SWAP_ROUTER.exactInputSingle(params);
    }

    function setWithdrawPool(uint256 _withdrawPool) external onlyOwner {
        withdrawPool = _withdrawPool;
    }

    function swapApeForPcApe(uint256 _amt) public onlyOwner {
        APE.approve(HELPER_CONTRACT_PARASPACE_ADDRESS, type(uint256).max);
        HELPER_CONTRACT_PARASPACE.convertApeCoinToPCApe(_amt);
    }

    function supplyToStrategy(uint256 _borrowAmt) external onlyOwner returns (uint256) {
        borrowFromAAVE(_borrowAmt);
        uint256 _apeBal = swapUSDCForApe(_borrowAmt);
        swapApeForPcApe(_apeBal);
        return _apeBal;
    }

    function withdrawCApeViaTimeLock(uint256 _amt) public onlyOwner {
        (bool _success, bytes memory _data) = address(POOL_APE_STAKING_ADDRESS).call(
            abi.encodeWithSignature(
                "withdraw(address,uint256,address)", 0xC5c9fB6223A989208Df27dCEE33fC59ff5c26fFF, _amt, address(this)
            )
        );
        require(_success, string(_data));
        agreementID = PARASPACE_TIMELOCK.agreementCount() - 1;
    }

    function claimCApeFromTimeLock() public onlyOwner {
        uint256[] memory arr = new uint[](1);
        arr[0] = agreementID;
        PARASPACE_TIMELOCK.claim(arr);
    }

    function withdrawApeForCApe(uint256 _amtCApe) public onlyOwner {
        (bool _success, bytes memory _data) =
            address(C_APE_ADDRESS).call(abi.encodeWithSignature("withdraw(uint256)", _amtCApe));
        require(_success, string(_data));
    }

    function getAAVEPosition()
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        (totalCollateralBase, totalDebtBase, availableBorrowsBase, currentLiquidationThreshold, ltv, healthFactor) =
            AAVE_POOL.getUserAccountData(address(this));
    }
}
