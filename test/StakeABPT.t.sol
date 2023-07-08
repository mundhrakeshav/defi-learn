// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {BaseTest} from "./Base.sol";
import {Config} from "../src/Config.sol";
import {ConfigurableRightsPool} from "../src/interfaces/ConfigurableRightsPool.sol";
import {BPool} from "../src/interfaces/BPool.sol";

contract StakeABPT is BaseTest, Config {
    function setUp() public override {
        super.setUp();
    }

    function testAddLiquidity() public {
        hoax(address(this));
        uint256[] memory _amts = new uint[](2);
        _amts[0] = 8e18;
        _amts[1] = 2e18;
        deal(AAVE_ADDRESS, address(this), 1e24, true);
        WETH.deposit{value: 1e24}();
        // emit log_uint(AAVE.balanceOf(address(this)));
        // emit log_uint(WETH.balanceOf(address(this)));
        AAVE.approve(B_ACTIONS_ADDRESS, 8e18);
        WETH.approve(B_ACTIONS_ADDRESS, 8e18);
        uint256 amtAAVE = 8e18;
        uint256 poolTotal = ConfigurableRightsPool(0x41A08648C3766F9F9d85598fF102a08f4ef84F84).totalSupply();
        BPool pool = ConfigurableRightsPool(0x41A08648C3766F9F9d85598fF102a08f4ef84F84).bPool();
        uint256 poolBal = pool.getBalance(AAVE_ADDRESS);
        uint256 amtOut = (amtAAVE * (poolTotal - 1)) / poolBal;
        emit log_uint(amtOut);
        B_ACTIONS.joinSmartPool(ConfigurableRightsPool(0x41A08648C3766F9F9d85598fF102a08f4ef84F84), amtOut, _amts);
        // emit log_uint(AAVE.balanceOf(address(this)));
        // emit log_uint(WETH.balanceOf(address(this)));
        // emit log_uint(ConfigurableRightsPool(0x41A08648C3766F9F9d85598fF102a08f4ef84F84).balanceOf(address(this)));
    }
}
