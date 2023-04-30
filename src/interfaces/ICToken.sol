// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IComptroller} from "./IComptroller.sol";
import {IInterestRateModel} from "./IInterestRateModel.sol";
import {IErrors} from "./IErrors.sol";

interface ICToken is IErrors {
    // Errors
    error InitialExchangeRateTooLow();
    error BorrowRateVHigh();

    // Market
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);
    event RepayBorrow(
        address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows
    );
    event LiquidateBorrow(
        address liquidator, address borrower, uint256 repayAmount, address cTokenCollateral, uint256 seizeTokens
    );

    // Admin
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * User Interface **
     */

    // function balanceOfUnderlying(address owner) external returns (uint);
    // function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    // function borrowRatePerBlock() external view returns (uint);
    // function supplyRatePerBlock() external view returns (uint);
    // function totalBorrowsCurrent() external returns (uint);
    // function borrowBalanceCurrent(address account) external returns (uint);
    // function borrowBalanceStored(address account) external view returns (uint);
    // function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    // function getCash() external view returns (uint);
    function accrueInterest() external;
    // function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    // /*** Admin Functions ***/

    // function setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    // function acceptAdmin() external returns (uint);
    function setComptroller(IComptroller newComptroller) external;
    // function setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    // function reduceReserves(uint reduceAmount) external returns (uint);
    // function setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint);
}
