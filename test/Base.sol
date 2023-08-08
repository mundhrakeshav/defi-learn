// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

abstract contract BaseTest is Test {
    string RPC_URL = "https://polygon-mainnet.g.alchemy.com/v2/BIzTr_LWkt7cNGfUUkNLpN93Cj0TFqjO";

    function setUp() public virtual {
        uint256 forkId = vm.createFork(RPC_URL, 45851752);
        vm.selectFork(forkId);
        hoax(address(this));
    }
}
