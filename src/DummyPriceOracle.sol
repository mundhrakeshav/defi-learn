// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract DummyPriceOracle {
    mapping(address => uint256) internal prices;

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function setAssetPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }
}
