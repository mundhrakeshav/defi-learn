// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {AggregatorInterface} from "chainlink/interfaces/AggregatorInterface.sol";

contract PriceOracle {
    mapping(address => address) internal sources;

    function getAssetPrice(address asset) external view returns (uint256) {
        return uint256(AggregatorInterface(sources[asset]).latestAnswer());
    }

    function setSource(address asset, address _src) external {
        sources[asset] = _src;
    }
}
