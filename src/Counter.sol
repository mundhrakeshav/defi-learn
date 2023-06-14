// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "solmate/src/tokens/ERC20.sol";
contract Counter is ERC20("Lock", "LOCK", 18) {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
