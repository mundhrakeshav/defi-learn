// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SafeFactory/GnosisSafeProxyFactory.sol";

abstract contract SafeConfig {
    address constant safeSingletonAddress = 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552;
    address constant safeFactoryAddress = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;

    GnosisSafeProxyFactory constant safeFactory = GnosisSafeProxyFactory(safeFactoryAddress);
}
