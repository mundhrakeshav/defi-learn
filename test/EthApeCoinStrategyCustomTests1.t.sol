// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "./Base.sol";
import {EthApeCoinStrategy} from "../src/EthApeCoinStrategy.sol";
import {Config} from "../src/Config.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {LibString} from "solmate/src/utils/LibString.sol";
import {DummyPriceOracle} from "src/DummyPriceOracle.sol";
import {PriceOracle} from "src/PriceOracle.sol";
import "forge-std/console.sol";

contract EthApeCoinStrategyCustomTest is BaseTest, Config {
    uint256 public constant PRECISION = 1e18;
    DummyPriceOracle public dummyPriceOracle;
    PriceOracle public priceOracle;
    EthApeCoinStrategy public strategy;
    address burnAddr = makeAddr("BURN");
    address depositor1 = makeAddr("DEPOSITOR1");
    address depositor2 = makeAddr("DEPOSITOR2");
    address depositor3 = makeAddr("DEPOSITOR3");
    address admin = makeAddr("ADMIN");
    string SPACE = " ";

    function setUp() public override {
        super.setUp();
        priceOracle = new PriceOracle();
        dummyPriceOracle = new DummyPriceOracle();
        strategy = new EthApeCoinStrategy(admin, address(dummyPriceOracle));
        priceOracle.setSource(APE_COIN_ADDRESS, CHAINLINK_APE_USD_AGGREGATOR_ADDRESS);
        priceOracle.setSource(USDC_ADDRESS, CHAINLINK_USDC_USD_AGGREGATOR_ADDRESS);
        priceOracle.setSource(WETH_ADDRESS, CHAINLINK_ETH_USD_AGGREGATOR_ADDRESS);
    }

    function setAssetPricesDummyOracle(uint256 _wethPrice, uint256 _usdcPrice, uint256 _apePrice) internal {
        dummyPriceOracle.setAssetPrice(WETH_ADDRESS, _wethPrice);
        dummyPriceOracle.setAssetPrice(USDC_ADDRESS, _usdcPrice);
        dummyPriceOracle.setAssetPrice(APE_COIN_ADDRESS, _apePrice);
    }

    function testDepositCustom1() public {
        setAssetPricesDummyOracle(1750e8, 1e8, 2.05e8);
        //
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        // Borrow
        uint256 _borrowAmt = 875_000_000; // 1750e6/2;
        hoax(admin);
        strategy.borrowFromAAVE(_borrowAmt);
        //
        uint256 _apeAmtAfterSwap = 426829268292682926829;
        //(1750*1e18*1e6)/(2*2.05e6); //2.05e6 = 2050000
        mimicSwap(USDC_ADDRESS, APE_COIN_ADDRESS, _borrowAmt, _apeAmtAfterSwap, address(strategy));
        startHoax(admin);
        strategy.swapApeForPcApe(APE.balanceOf(address(strategy)));
        vm.stopPrank();
        console.log("DAY0 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
        skip(2 days);
        setAssetPricesDummyOracle(1770e8, 1e8, 2e8);
        console.log("DAY2 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
        skip(8 days);
        setAssetPricesDummyOracle(1810e8, 1e8, 2.10e8);
        console.log("DAY00 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
        skip(20 days);
        setAssetPricesDummyOracle(1720e8, 1e8, 1.75e8);
        console.log("DAY30 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
        skip(45 days);
        setAssetPricesDummyOracle(1985e8, 1e8, 1.5e8);
        console.log("DAY75 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
    }


    function testDepositCustom2() public {
        setAssetPricesDummyOracle(1750e8, 1e8, 2.05e8);
        //
        hoax(admin);
        strategy.approveToken(ERC20(WETH_ADDRESS), AAVE_POOL_ADDRESS, type(uint256).max);
        // Deposit
        hoax(depositor1);
        strategy.deposit{value: 1 ether}(depositor1);
        // Borrow
        uint256 _borrowAmt = 875_000_000; // 1750e6/2;
        hoax(admin);
        strategy.borrowFromAAVE(_borrowAmt);
        //
        uint256 _apeAmtAfterSwap = 426829268292682926829;
        //(1750*1e18*1e6)/(2*2.05e6); //2.05e6 = 2050000
        mimicSwap(USDC_ADDRESS, APE_COIN_ADDRESS, _borrowAmt, _apeAmtAfterSwap, address(strategy));
        startHoax(admin);
        strategy.swapApeForPcApe(APE.balanceOf(address(strategy)));
        vm.stopPrank();
        console.log("DAY0 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
        skip(2 days);
        setAssetPricesDummyOracle(1710e8, 1e8, 2.1e8);
        console.log("DAY2 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
        skip(8 days);
        setAssetPricesDummyOracle(1650e8, 1e8, 2.45e8);
        console.log("DAY00 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
        skip(20 days);
        setAssetPricesDummyOracle(1700e8, 1e8, 3.2e8);
        console.log("DAY30 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
        skip(45 days);
        setAssetPricesDummyOracle(1550e8, 1e8, 3.95e8);
        console.log("DAY75 EthValue: ", strategy.getEthForShare(strategy.balanceOf(depositor1)));
    }

    function mimicSwap(address _fromToken, address _toToken, uint256 _inAmt, uint256 _outAmt, address _user) internal {
        // string memory _log = string(abi.encodePacked("Swapping ", LibString.toString(_inAmt), " ", LibString.toString(_outAmt)));
        console.log("Swapping", ERC20(_fromToken).symbol(), "to", ERC20(_toToken).symbol());
        console.log("Swapping", LibString.toString(_inAmt), "to", LibString.toString(_outAmt));
        deal(_toToken, _user, _outAmt, true);
        vm.prank(_user);
        ERC20(_fromToken).transfer(burnAddr, _inAmt);
    }

    function _logUserAccountData(address _user, string memory _details) private {
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

    function _setAaveOracle(address _oracleAddr) internal {
        hoax(AAVE_ADMIN);
        AAVE_POOL_ADDRESSES_PROVIDER.setPriceOracle(_oracleAddr);
    }
}
