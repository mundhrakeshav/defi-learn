// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IPool} from "./AAVE/IPool.sol";
import {IWETH9} from "./IWETH9.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

// Precision for price in USD is 1e8
contract EthApeCoinStrategy is Owned, ERC20("EACS", "EACS", 18) {
    address public aavePoolAddress = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IPool public aavePool = IPool(aavePoolAddress);
    IWETH9 public weth = IWETH9(wethAddress);
    ERC20 public usdc = ERC20(usdcAddress);
    ERC20 public dai = ERC20(daiAddress);

    address public admin;

    constructor(address _owner) Owned(_owner) {}

    function approveToken(ERC20 _token, address _spender, uint256 _amt) external onlyOwner {
        _token.approve(_spender, _amt);
    }

    function deposit() external payable {
        weth.deposit{value: msg.value}();
        aavePool.supply(wethAddress, msg.value, address(this), 0);
        // Add logic for handling shares
    }

    function borrowFromAAVE(address _asset, uint256 _amount) external onlyOwner {
        aavePool.borrow(_asset, _amount, 2, 0, address(this));
    }

}
