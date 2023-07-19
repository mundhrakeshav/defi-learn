// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }
    // Initializes a tick if it had 0 liquidity and adds new liquidity to it.

    function update(mapping(int24 => Tick.Info) storage self, int24 tick, uint128 liquidityDelta)
        internal
        returns (bool flipped)
    {
        Tick.Info storage tickInfo = self[tick];
        uint128 liquidityBefore = tickInfo.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;
        flipped = (liquidityAfter == 0) != (liquidityBefore == 0);

        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }

        tickInfo.liquidity = liquidityAfter;
    }
}
