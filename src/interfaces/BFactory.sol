// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BPool} from "./BPool.sol";

abstract contract BFactory {
    function newBPool() external virtual returns (BPool);
}
