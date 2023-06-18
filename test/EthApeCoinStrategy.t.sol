// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "./Base.sol";
import {EthApeCoinStrategy} from "../src/EthApeCoinStrategy.sol";
import {DataTypes} from "../src/AAVE/DataTypes.sol";
import {Config} from "../src/Config.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {DummyPriceOracle} from "src/DummyPriceOracle.sol";
import {PriceOracle} from "src/PriceOracle.sol";
import "forge-std/console.sol";

contract EthApeCoinStrategyTest is BaseTest, Config {
    uint256 public constant PRECISION = 1e18;
    DummyPriceOracle public dummyPriceOracle;
    PriceOracle public priceOracle;
    EthApeCoinStrategy public strategy;
    address depositor1 = makeAddr("DEPOSITOR1");
    address depositor2 = makeAddr("DEPOSITOR2");
    address depositor3 = makeAddr("DEPOSITOR3");
    address admin = makeAddr("ADMIN");

    function setUp() public override {
        super.setUp();
        priceOracle = new PriceOracle();
        dummyPriceOracle = new DummyPriceOracle();
        strategy = new EthApeCoinStrategy(admin, address(priceOracle));
        priceOracle.setSource(APE_COIN_ADDRESS, CHAINLINK_APE_USD_AGGREGATOR_ADDRESS);
        priceOracle.setSource(USDC_ADDRESS, CHAINLINK_USDC_USD_AGGREGATOR_ADDRESS);
        priceOracle.setSource(WETH_ADDRESS, CHAINLINK_ETH_USD_AGGREGATOR_ADDRESS);
    }

    function testDeposit() public {
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        assertEq(strategy.balanceOf(depositor1), 1 ether);
        assertEq(AAVE_ETH_WETH.balanceOf(address(strategy)), 1 ether);
        hoax(depositor2);
        strategy.deposit{value: 1 ether}(depositor2);
        assertEq(strategy.balanceOf(depositor2), 1 ether);
        assertApproxEqAbs(AAVE_ETH_WETH.balanceOf(address(strategy)), 2 ether, 1);
    }

    function testDepositPriceChange() public {
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        strategy.setOracle(address(dummyPriceOracle));
        setAaveOracle(address(dummyPriceOracle));
        dummyPriceOracle.setAssetPrice(WETH_ADDRESS, 2000e8);
        dummyPriceOracle.setAssetPrice(USDC_ADDRESS, 1e8);
        dummyPriceOracle.setAssetPrice(APE_COIN_ADDRESS, 2e8);
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        assertEq(strategy.balanceOf(depositor1), 1 ether);
        assertEq(AAVE_ETH_WETH.balanceOf(address(strategy)), 1 ether);
        hoax(depositor2);
        strategy.deposit{value: 1 ether}(depositor2);
        assertEq(strategy.balanceOf(depositor2), 1 ether);
        assertApproxEqAbs(AAVE_ETH_WETH.balanceOf(address(strategy)), 2 ether, 1);
    }

    function testAdminBorrow() public {
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        assertEq(strategy.balanceOf(depositor1), 1 ether);
        assertEq(AAVE_ETH_WETH.balanceOf(address(strategy)), 1 ether);
        hoax(depositor2);
        strategy.deposit{value: 1 ether}(depositor2);
        assertEq(strategy.balanceOf(depositor2), 1 ether);
        assertApproxEqAbs(AAVE_ETH_WETH.balanceOf(address(strategy)), 2 ether, 1);
        //
        hoax(admin);
        strategy.borrowFromAAVE(2000e6);
        //
        assertEq(USDC.balanceOf(address(strategy)), 2000e6);
        assertEq(AAVE_VARIABLE_DEBT_USDC.balanceOf(address(strategy)), 2000e6);
    }

    function testAdminSwap() public {
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        hoax(depositor2);
        strategy.deposit{value: 1 ether}(depositor2);
        //
        hoax(admin);
        strategy.borrowFromAAVE(2000e6);
        //
        hoax(admin);
        uint256 _apeBal = strategy.swapUSDCForApe(2000e6);
        assertEq(APE.balanceOf(address(strategy)), _apeBal);
    }

    function testDepositForPcApe() public {
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        hoax(depositor2);
        strategy.deposit{value: 1 ether}(depositor2);
        //
        startHoax(admin);
        strategy.borrowFromAAVE(2000e6);
        //
        uint256 _apeBal = strategy.swapUSDCForApe(2000e6);
        //
        // uint _apeBal = APE.balanceOf(address(strategy));
        strategy.swapApeForPcApe(APE.balanceOf(address(strategy)));
        vm.stopPrank();
        assertEq(PC_APE.balanceOf(address(strategy)), _apeBal);
    }

    function testSwapPcApeForApe() public {
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        hoax(depositor2);
        strategy.deposit{value: 1 ether}(depositor2);
        //
        startHoax(admin);
        uint256 _apeBal = strategy.supplyToStrategy(2000e6);
        assertEq(PC_APE.balanceOf(address(strategy)), _apeBal);
        skip(30 days);
        console.log(PC_APE.balanceOf(address(strategy)));
        // strategy.swapPcApeForApe(1000);
        // vm.stopPrank();
    }

    function testSupply() public {
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        hoax(depositor2);
        strategy.deposit{value: 1 ether}(depositor2);
        //
        startHoax(admin);
        uint256 _apeBal = strategy.supplyToStrategy(2000e6);
        vm.stopPrank();
        assertEq(PC_APE.balanceOf(address(strategy)), _apeBal);
    }

    function logUserAccountData(address _user, string memory _details) private {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = AAVE_POOL.getUserAccountData(_user);

        emit log_string("------------------------------------------------------------------");
        emit log_string(_details);
        emit log_named_uint("Collateral", totalCollateralBase);
        emit log_named_uint("Debt", totalDebtBase);
        emit log_named_uint("Available Borrow", availableBorrowsBase);
        emit log_named_uint("Health Factor", healthFactor);
        emit log_named_uint("LTV", ltv);
        emit log_named_uint("Liquidation threshold", currentLiquidationThreshold);
    }

    function setAaveOracle(address _oracleAddr) internal {
        hoax(AAVE_ADMIN);
        AAVE_POOL_ADDRESSES_PROVIDER.setPriceOracle(_oracleAddr);
    }

    function changeScaleUSDC(uint256 _amt) internal pure returns (uint256) {
        return (_amt * 1e6) / 1e8;
    }
}
