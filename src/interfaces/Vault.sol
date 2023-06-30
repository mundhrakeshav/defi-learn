// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Vault {
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest calldata request)
        external
        virtual;
    function getPoolTokens(bytes32 poolId)
        external
        view
        virtual
        returns (address[] memory, uint256[] memory, uint256);
}
