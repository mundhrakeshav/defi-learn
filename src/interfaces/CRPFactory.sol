// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ConfigurableRightsPool} from "./ConfigurableRightsPool.sol";
import {RightsManager} from "./RightsManager.sol";

abstract contract CRPFactory {
    function newCrp(
        address factoryAddress,
        ConfigurableRightsPool.PoolParams calldata params,
        RightsManager.Rights calldata rights
    ) external virtual returns (ConfigurableRightsPool);
}
