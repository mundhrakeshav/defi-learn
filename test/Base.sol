// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

abstract contract BaseTest is Test {
    string RPC_URL = "https://eth-mainnet.g.alchemy.com/v2/zE4hvUo53cxgwTRp7UI2zi2tzDQ0QtbB";

    function setUp() public virtual {
        uint256 forkId = vm.createFork(RPC_URL, 16806984);
        vm.selectFork(forkId);
        hoax(address(this));
    }
}
