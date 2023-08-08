// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IVault} from "./IVault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract BalancerConfig {
    address constant public VAULT_V2_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant public W_MATIC_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    //
    IVault constant public VAULT_V2 = IVault(VAULT_V2_ADDRESS);
    ERC20 constant public W_MATIC = ERC20(W_MATIC_ADDRESS);
}