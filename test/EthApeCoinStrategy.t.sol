// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "./Base.sol";
import {EthApeCoinStrategy} from "../src/EthApeCoinStrategy.sol";
import {DataTypes} from "../src/AAVE/DataTypes.sol";
import {Config} from "../src/Config.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {DummyPriceOracle} from "./DummyPriceOracle.sol";


contract EthApeCoinStrategyTest is BaseTest, Config {
    uint256 public constant PRECISION = 1e18;
    DummyPriceOracle public dummyPriceOracle = new DummyPriceOracle();
    EthApeCoinStrategy public strategy;
    address depositor1 = makeAddr("DEPOSITOR1");
    address depositor2 = makeAddr("DEPOSITOR2");
    address depositor3 = makeAddr("DEPOSITOR3");
    address admin = makeAddr("ADMIN");

    function setUp() public override {
        super.setUp();
        strategy = new EthApeCoinStrategy(admin);
    }

    function setAaveOracle() internal {
        hoax(AAVE_ADMIN);
        AAVE_POOL_ADDRESSES_PROVIDER.setPriceOracle(address(dummyPriceOracle));
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
        assertEq(AAVE_ETH_WETH.balanceOf(address(strategy)), 2 ether);
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
        assertEq(AAVE_ETH_WETH.balanceOf(address(strategy)), 2 ether);
        //
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = AAVE_POOL.getUserAccountData(address(strategy));
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

    // function testDeposit() public {
    //     hoax(admin);
    //     strategy.approveToken(ERC20(wethAddress), aavePoolAddress, type(uint256).max);
    //     // Deposit
    //     hoax(depositor);
    //     strategy.deposit{value: 1 ether}();
    //     emit log_uint(AAVE_ETH_WETH.balanceOf(address(strategy)));
    //     // DataTypes.ReserveData memory _reserveData = aavePool.getReserveData(wethAddress);
    //     // ERC20 _aToken = ERC20(_reserveData.aTokenAddress);
    //     // (,, uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(address(strategy));
    //     // logUserAccountData(address(strategy), string("Deposited"));
    //     // // Borrow
    //     // hoax(admin);
    //     // strategy.borrowFromAAVE(usdcAddress, changeScaleUSDC(availableBorrowsBase) / 2);
    //     // logUserAccountData(address(strategy), string("Borrowed"));
    //     // // Swap
    //     // hoax(admin);
    //     // strategy.swapUSDCForApe();
    //     // emit log_uint(ape.balanceOf(address(strategy)));
    //     // //
    //     // hoax(admin);
    //     // strategy.swapApeForPCAPE();
    //     // emit log_uint(ape.balanceOf(address(strategy)));
    //     // emit log_uint(pcApe.balanceOf(address(strategy)));
    // }
