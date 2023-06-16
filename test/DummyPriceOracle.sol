// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../src/AAVE/IPriceOracle.sol";

contract DummyPriceOracle is IPriceOracle {
    mapping(address => uint256) internal prices;

    address public BASE_CURRENCY;
    uint256 public BASE_CURRENCY_UNIT = 1e8;

    function getAssetPrice(address asset) external view returns (uint256){
        return prices[asset];
    }

    function setAssetPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }
}
