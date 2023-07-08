// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

abstract contract BaseTest is Test {
    string RPC_URL = "https://eth-mainnet.g.alchemy.com/v2/2I_CHno5SzLZTBSzdy7wLFtj5HEg4uNC";

    function setUp() public virtual {
        uint256 forkId = vm.createFork(RPC_URL);
        vm.selectFork(forkId);
        hoax(address(this));
    }
}
