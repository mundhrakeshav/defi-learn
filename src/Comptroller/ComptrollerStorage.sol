// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AdminStorage} from "./AdminStorage.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {ICToken} from "../interfaces/ICToken.sol";

contract ComptrollerStorage is AdminStorage {
    //
    struct Market {
        // Whether or not this market is listed
        bool isListed;
        //  Multiplier representing the most one can borrow against their collateral in this market.
        //  For instance, 0.9 to allow borrowing 90% of collateral value.
        //  Must be between 0 and 1, and stored as a mantissa.
        uint256 collateralFactorMantissa;
        // Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;
        // Whether or not this market receives COMP
        bool isComped;
    }

    struct MarketState {
        // The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        // The block number the index was last updated at
        uint32 block;
    }
    /**
     * @notice Oracle which gives the price of any given asset
     */

    IPriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => ICToken[]) public accountAssets;

    /**
     * @notice Official mapping of cTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(ICToken => Market) public markets;

    /// @notice A list of all markets
    ICToken[] public allMarkets;

    /// @notice The market supply state for each market
    mapping(address => MarketState) public supplyState;

    /// @notice The market borrow state for each market
    mapping(address => MarketState) public borrowState;

    /// @notice The borrow index for each market for each supplier as of the last time they accrued COMP
    mapping(address => mapping(address => uint256)) public supplierIndex;

    /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
    mapping(address => mapping(address => uint256)) public borrowerIndex;
}
