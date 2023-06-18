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

    constructor(address _owner, address _oracle) Owned(_owner) {
        oracle = IPriceOracle(_oracle);
    }

    function getPositions() public view returns (uint256 _aEthWethColl, uint256 _aVariableDebtUSDC, uint256 _apeBal) {
        _aEthWethColl = AAVE_ETH_WETH.balanceOf(address(this));
        _aVariableDebtUSDC = AAVE_VARIABLE_DEBT_USDC.balanceOf(address(this));
        _apeBal = C_APE.balanceOf(address(this));
    }

    function getPrice(address _asset) public view returns (uint256) {
        return oracle.getAssetPrice(_asset); // Precision of 1e8
    }

    function setOracle(address _oracle) public {
        oracle = IPriceOracle(_oracle);
    }

    function getNetAsset()
        public
        view
        returns (uint256 _apeUSD, uint256 _usdcDebtUSD, uint256 _ethCollUSD, uint256 _netUSDAmt)
    {
        (uint256 _aEthWethColl, uint256 _aVariableDebtUSDC, uint256 _apeBal) = getPositions();
        _apeUSD = getPrice(APE_COIN_ADDRESS) * _apeBal;
        _usdcDebtUSD = getPrice(USDC_ADDRESS) * _aVariableDebtUSDC;
        _ethCollUSD = getPrice(WETH_ADDRESS) * _aEthWethColl;

        _netUSDAmt = _apeUSD + _ethCollUSD - _usdcDebtUSD;
    }

    function getShareForUSD(uint256 _amtUSD) public view returns (uint256) {
        (,,, uint256 _netUSDAmt) = getNetAsset();
        return (_amtUSD * totalSupply) / _netUSDAmt;
    }

    function getShareForEth(uint256 _amtEth) public view returns (uint256) {
        (,,, uint256 _netUSDAmt) = getNetAsset();
        uint256 _ethAmtUSD = getPrice(WETH_ADDRESS) * _amtEth;
        return (_ethAmtUSD * totalSupply) / _netUSDAmt;
        // 1e8                      // 1e8
    }

    function approveToken(ERC20 _token, address _spender, uint256 _amt) external onlyOwner {
        _token.approve(_spender, _amt);
    }

    function deposit(address _to) external payable {
        WETH.deposit{value: msg.value}();
        if (totalSupply == 0) {
            _mint(_to, msg.value);
        } else {
            uint256 _shares = getShareForEth(msg.value);
            _mint(_to, _shares);
        }
        AAVE_POOL.supply(WETH_ADDRESS, msg.value, address(this), 0);
    }

    function borrowFromAAVE(uint256 _amount) public onlyOwner {
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
            deadline: block.timestamp,
            amountIn: _amt,
            amountOutMinimum: 0,
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

    function swapPcApeForApe(uint256 _amt) public onlyOwner {
        PC_APE.approve(HELPER_CONTRACT_PARASPACE_ADDRESS, type(uint256).max);
        HELPER_CONTRACT_PARASPACE.convertPCApeToApeCoin(_amt);
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
