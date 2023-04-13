// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/ICERC20.sol";
import "../interfaces/IComptroller.sol";
import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";

abstract contract CERC20Storage is ICERC20 {
    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }

    // Maximum borrow rate that can ever be applied (.0005% / block)
    // 0.0005%
    uint256 internal constant borrowRateMaxMantissa = 0.000005e18;

    // Maximum fraction of interest that can be set aside for reserves
    // Expressed in scale 1e18, 1e18 = 100%
    uint256 internal constant reserveFactorMaxMantissa = 1e18;

    // Indicator that this is a CToken contract
    bool public constant isCToken = true;

    // Share of seized collateral that is added to reserves
    uint256 public constant protocolSeizeShareMantissa = 0.028e18; //2.8%

    // Guard variable for re-entrancy checks
    bool internal _notEntered;

    // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    // Expressed in scale 1e18
    uint256 internal initialExchangeRateMantissa;

    // Official record of token balances for each account
    mapping(address => uint256) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    string public name;
    string public symbol;
    uint8 public decimals;

    address public underlying; // underlying asset
    address payable public admin;
    address payable public pendingAdmin;
    IComptroller public comptroller;
    IInterestRateModel public interestRateModel;

    // Fraction of interest currently set aside for reserves
    uint256 public reserveFactorMantissa;

    // notice Block number that interest was last accrued at
    uint256 public accrualBlockNumber;

    // Accumulator of the total earned interest rate since the opening of the market
    uint256 public borrowIndex;

    // Total amount of outstanding borrows of the underlying in this market
    uint256 public totalBorrows;

    // Total amount of reserves of the underlying held in this market
    uint256 public totalReserves;

    // Total number of tokens in circulation
    uint256 public totalSupply;
}
