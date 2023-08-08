// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseTest} from "./Base.sol";
import {IVault, IAsset} from "../src/IVault.sol";
import {BalancerConfig} from "../src/Balancer.config.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract BalancerTest is BaseTest, BalancerConfig {
    address user1 = makeAddr("user1");

    function setUp() public override {
        BaseTest.setUp();
    }

    function testSwap() public {
        deal(W_MATIC_ADDRESS, user1, 1e20);
        IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](2);
        bytes memory ud = "";
        swaps[0] = IVault.BatchSwapStep({
            poolId: 0xb0c830dceb4ef55a60192472c20c8bf19df03488000000000000000000000be1,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: 5000000000000000000,
            userData: ud
        });
        swaps[1] = IVault.BatchSwapStep({
            poolId: 0x402cfdb7781fa85d52f425352661128250b79e12000000000000000000000be3,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0,
            userData: ud
        });
        IVault.FundManagement memory funds;
        IAsset[] memory assets = new IAsset[](3);
        assets[0] = IAsset(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
        assets[1] = IAsset(0xb0C830DCeB4EF55A60192472c20C8bf19dF03488);
        assets[2] = IAsset(0x402cFDb7781fa85d52F425352661128250B79e12);
        funds = IVault.FundManagement({
            sender: user1,
            fromInternalBalance: false,
            recipient: payable(user1),
            toInternalBalance: false
        });
        int256[] memory lim = VAULT_V2.queryBatchSwap(IVault.SwapKind.GIVEN_IN, swaps, assets, funds);
        emit log_int(lim[0]);
        emit log_int(lim[1]);
        emit log_int(lim[2]);
        vm.startPrank(user1);
        W_MATIC.approve(VAULT_V2_ADDRESS, 1e30);
        VAULT_V2.batchSwap(IVault.SwapKind.GIVEN_IN, swaps, assets, funds, lim, 1e18);
        emit log_uint(ERC20(0x402cFDb7781fa85d52F425352661128250B79e12).balanceOf(user1));
    }
}
