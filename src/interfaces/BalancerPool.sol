// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

abstract contract BalancerPool is ERC20 {
    function getPoolId() external view virtual returns (bytes32);

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT
    }
}
