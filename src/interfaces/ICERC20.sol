// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICERC20 {
    function mint(uint mintAmount) external returns (uint);
}