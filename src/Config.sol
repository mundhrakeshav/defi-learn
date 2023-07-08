// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import {BActions} from "./interfaces/BActions.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IWETH9} from "./IWETH9.sol";

contract Config {
    address constant B_ACTIONS_ADDRESS = 0xC27D3C1dDE27Fc79Acbbe76A90eBdfF3ef164660;
    address constant AAVE_ADDRESS = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ERC20 constant AAVE = ERC20(AAVE_ADDRESS);
    // ERC20 constant WETH = ERC20(WETH_ADDRESS);
    IWETH9 public constant WETH = IWETH9(WETH_ADDRESS);
    
    BActions constant B_ACTIONS = BActions(B_ACTIONS_ADDRESS);

}
