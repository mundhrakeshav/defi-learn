// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract AdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address public pendingAdmin;
}
