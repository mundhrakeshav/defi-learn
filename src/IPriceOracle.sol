// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}
