// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IComptroller} from "./IComptroller.sol";
import {IInterestRateModel} from "./IInterestRateModel.sol";
import {IErrors} from "./IErrors.sol";
interface ICToken is IErrors {
    // Errors
    error InitialExchangeRateTooLow();

    // Market
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);
    event Mint(address minter, uint mintAmount, uint mintTokens);
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);
    
    // Admin
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);
    
    // ERC20
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);


    /*** User Interface ***/

    // function transfer(address dst, uint amount) external returns (bool);
    // function transferFrom(address src, address dst, uint amount) external returns (bool);
    // function approve(address spender, uint amount) external returns (bool);
    // function allowance(address owner, address spender) external view returns (uint);
    // function balanceOf(address owner) external view returns (uint);
    // function balanceOfUnderlying(address owner) external returns (uint);
    // function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    // function borrowRatePerBlock() external view returns (uint);
    // function supplyRatePerBlock() external view returns (uint);
    // function totalBorrowsCurrent() external returns (uint);
    // function borrowBalanceCurrent(address account) external returns (uint);
    // function borrowBalanceStored(address account) external view returns (uint);
    // function exchangeRateCurrent() external returns (uint);
    // function exchangeRateStored() external view returns (uint);
    // function getCash() external view returns (uint);
    // function accrueInterest() external returns (uint);
    // function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);


    // /*** Admin Functions ***/

    // function setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    // function acceptAdmin() external returns (uint);
    function setComptroller(IComptroller newComptroller) external;
    // function setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    // function reduceReserves(uint reduceAmount) external returns (uint);
    // function setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint);
}