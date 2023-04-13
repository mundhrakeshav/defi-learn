// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IErrors {
    error OnlyAdmin();
    error AlreadyInitialized();
    error MarkerMethodErr();
    error MarketBlockNumberNotEqCurrentBlockNumber();

}