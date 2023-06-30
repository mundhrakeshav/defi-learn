// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AbstractPool} from "./AbstractPool.sol";
import {BPool} from "./BPool.sol";

abstract contract ConfigurableRightsPool is AbstractPool {
    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint256[] tokenBalances;
        uint256[] tokenWeights;
        uint256 swapFee;
    }

    struct CrpParams {
        uint256 initialSupply;
        uint256 minimumWeightChangeBlockPeriod;
        uint256 addTokenTimeLockInBlocks;
    }

    function createPool(uint256 initialSupply, uint256 minimumWeightChangeBlockPeriod, uint256 addTokenTimeLockInBlocks)
        external
        virtual;
    function createPool(uint256 initialSupply) external virtual;
    function setCap(uint256 newCap) external virtual;
    function updateWeight(address token, uint256 newWeight) external virtual;
    function updateWeightsGradually(uint256[] calldata newWeights, uint256 startBlock, uint256 endBlock)
        external
        virtual;
    function commitAddToken(address token, uint256 balance, uint256 denormalizedWeight) external virtual;
    function applyAddToken() external virtual;
    function removeToken(address token) external virtual;
    function whitelistLiquidityProvider(address provider) external virtual;
    function removeWhitelistedLiquidityProvider(address provider) external virtual;
    function bPool() external view virtual returns (BPool);
}
