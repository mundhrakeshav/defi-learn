// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

library DataTypes {
    enum AssetType {
        ERC20,
        ERC721
    }

    enum TimeLockActionType {
        BORROW,
        WITHDRAW
    }
}

interface ITimeLock {
    struct Agreement {
        DataTypes.AssetType assetType;
        DataTypes.TimeLockActionType actionType;
        bool isFrozen;
        address asset;
        address beneficiary;
        uint48 releaseTime;
        uint256[] tokenIdsOrAmounts;
    }

    function agreementCount() external returns (uint248);
    function createAgreement(
        DataTypes.AssetType assetType,
        DataTypes.TimeLockActionType actionType,
        address asset,
        uint256[] memory tokenIdsOrAmounts,
        address beneficiary,
        uint48 releaseTime
    ) external returns (uint256 agreementId);

    function getAgreement(uint256 agreementId) external view returns (Agreement memory agreement);
    function claim(uint256[] calldata agreementIds) external;
}
