// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

abstract contract BaseTest is Test {
    string RPC_URL = "https://mainnet.infura.io/v3/bdaefb510f71410d8e698f692309bac2";

    function setUp() public virtual {
        uint256 forkId = vm.createFork(RPC_URL, 17512921);
        vm.selectFork(forkId);
        hoax(address(this));
    }
}
