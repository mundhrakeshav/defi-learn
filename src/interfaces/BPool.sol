// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AbstractPool} from "./AbstractPool.sol";

abstract contract BPool is AbstractPool {
    function finalize() external virtual;
    function bind(address token, uint256 balance, uint256 denorm) external virtual;
    function rebind(address token, uint256 balance, uint256 denorm) external virtual;
    function unbind(address token) external virtual;
    function isBound(address t) external view virtual returns (bool);
    function getCurrentTokens() external view virtual returns (address[] memory);
    function getFinalTokens() external view virtual returns (address[] memory);
    function getBalance(address token) external view virtual returns (uint256);
}
