// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "./Base.sol";
import {EthApeCoinStrategy} from "../src/EthApeCoinStrategy.sol";
import {DataTypes} from "../src/AAVE/DataTypes.sol";
import {IPool} from "../src/AAVE/IPool.sol";
import {ISwapRouter} from "../src/Uniswap/ISwapRouter.sol";
import {IWETH9} from "../src/IWETH9.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract EthApeCoinStrategyTest is BaseTest {
    address public aavePoolAddress = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public apeCoinAddress = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    address public swapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public pcApeAddress = 0xDDDe38696FBe5d11497D72d8801F651642d62353;

    IPool public aavePool = IPool(aavePoolAddress);
    IWETH9 public weth = IWETH9(wethAddress);
    ERC20 public usdc = ERC20(usdcAddress);
    ERC20 public dai = ERC20(daiAddress);
    ERC20 public ape = ERC20(apeCoinAddress);
    ERC20 public pcApe = ERC20(pcApeAddress);
    ISwapRouter public swapRouter = ISwapRouter(swapRouterAddress);

    EthApeCoinStrategy public strategy;
    address depositor = makeAddr("DEPOSITOR");
    address admin = makeAddr("ADMIN");

    function setUp() public override {
        super.setUp();
        strategy = new EthApeCoinStrategy(admin);
    }

    function testDeposit() public {
        hoax(admin);
        strategy.approveToken(ERC20(wethAddress), aavePoolAddress, type(uint256).max);
        // Deposit
        hoax(depositor);
        strategy.deposit{value: 1 ether}();
        // DataTypes.ReserveData memory _reserveData = aavePool.getReserveData(wethAddress);
        // ERC20 _aToken = ERC20(_reserveData.aTokenAddress);
        (,, uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(address(strategy));
        logUserAccountData(address(strategy), string("Deposited"));
        // Borrow
        hoax(admin);
        strategy.borrowFromAAVE(usdcAddress, changeScaleUSDC(availableBorrowsBase) / 2);
        logUserAccountData(address(strategy), string("Borrowed"));
        // Swap
        hoax(admin);
        strategy.swapUSDCForApe();
        emit log_uint(ape.balanceOf(address(strategy)));
        //
        hoax(admin);
        strategy.swapApeForPCAPE();
        emit log_uint(ape.balanceOf(address(strategy)));
        emit log_uint(pcApe.balanceOf(address(strategy)));
    }

    function logUserAccountData(address _user, string memory _details) private {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = aavePool.getUserAccountData(_user);

        emit log_string("------------------------------------------------------------------");
        emit log_string(_details);
        emit log_named_uint("Collateral", totalCollateralBase);
        emit log_named_uint("Debt", totalDebtBase);
        emit log_named_uint("Available Borrow", availableBorrowsBase);
        emit log_named_uint("Health Factor", healthFactor);
        emit log_named_uint("LTV", ltv);
        emit log_named_uint("Liquidation threshold", currentLiquidationThreshold);
    }

    function changeScaleUSDC(uint256 _amt) internal pure returns (uint256) {
        return (_amt * 1e6) / 1e8;
    }
}
