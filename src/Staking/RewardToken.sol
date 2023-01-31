// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract RewardToken is ERC20("RewardToken", "RT", 18) {
    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}
