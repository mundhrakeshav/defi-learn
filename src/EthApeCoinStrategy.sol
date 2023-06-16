// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {AggregatorV3Interface} from "chainlink/interfaces/AggregatorV3Interface.sol";
import {ISwapRouter} from "./Uniswap/ISwapRouter.sol";
import {Config} from "./Config.sol";

// Precision for price in USD is 1e8
contract EthApeCoinStrategy is Owned, ERC20("EACS", "EACS", 18), Config {
    uint256 public constant PRECISION = 1e18;
    uint24 public constant poolFee = 3000;

    enum BorrowRate {
        INVALID,
        STABLE,
        VARIABLE
    }

    uint256 public withdrawPool;

    constructor(address _owner) Owned(_owner) {}

    function getPositions(address _addr)
        public
        view
        returns (uint256 _aEthWethColl, uint256 _aVariableDebtUSDC, uint256 _apeBal)
    {
        _aEthWethColl = AAVE_ETH_WETH.balanceOf(_addr);
        _aVariableDebtUSDC = AAVE_VARIABLE_DEBT_USDC.balanceOf(_addr);
        _apeBal = C_APE.balanceOf(_addr);
    }

    function getShareToAmt(uint256 _amt) public view {}

    function approveToken(ERC20 _token, address _spender, uint256 _amt) external onlyOwner {
        _token.approve(_spender, _amt);
    }

    function deposit(address _to) external payable {
        uint256 aTokens = AAVE_ETH_WETH.balanceOf(address(this));
        WETH.deposit{value: msg.value}();
        AAVE_POOL.supply(WETH_ADDRESS, msg.value, address(this), 0);
        withdrawPool += msg.value;
        if (totalSupply == 0) {
            _mint(_to, msg.value);
        } else {
            uint256 _shares = (msg.value * totalSupply) / aTokens;
            _mint(_to, _shares);
        }
    }

    function borrowFromAAVE(address _asset, uint256 _amount) external onlyOwner {
        AAVE_POOL.borrow(_asset, _amount, uint256(BorrowRate.VARIABLE), 0, address(this));
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

    function swapUSDCForApe() external onlyOwner {
        uint256 _amt = USDC.balanceOf(address(this));
        //
        USDC.approve(SWAP_ROUTER_ADDRESS, _amt);
        //
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: USDC_ADDRESS,
            tokenOut: APE_COIN_ADDRESS,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amt,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        //
        SWAP_ROUTER.exactInputSingle(params);
    }

    function swapApeForPCAPE() external onlyOwner {
        uint256 _amt = APE.balanceOf(address(this));
        APE.approve(HELPER_CONTRACT_PARASPACE_ADDRESS, type(uint256).max);

        HELPER_CONTRACT_PARASPACE.convertApeCoinToPCApe(_amt);
    }
}
