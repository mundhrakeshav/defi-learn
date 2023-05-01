// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CERC20Storage} from "./CERC20Storage.sol";
import {IComptroller} from "../interfaces/IComptroller.sol";
import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";
import {ExponentialNoError} from "../ExponentialNoError.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract CERC20 is CERC20Storage, ExponentialNoError {
    constructor(
        ERC20 _underlying,
        IComptroller _comptroller,
        IInterestRateModel _interestRateModel,
        uint256 _initialExchangeRateMantissa,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        // Below statement would be needed if we use a proxy and an initialize function instead of constructor
        // if (accrualBlockNumber != 0 || borrowIndex != 0) revert AlreadyInitialized();

        if (_initialExchangeRateMantissa == 0) revert InitialExchangeRateTooLow();

        initialExchangeRateMantissa = _initialExchangeRateMantissa;

        // setComptroller(_comptroller);
        comptroller = _comptroller;

        accrualBlockNumber = block.number;
        borrowIndex = MANTISSA_ONE;

        // setInterestRateModelFresh(_interestRateModel);
        interestRateModel = _interestRateModel;

        underlying = _underlying;
        _notEntered = true;
    }

    function setComptroller(IComptroller newComptroller) public override {
        IComptroller oldComptroller = comptroller;
        if (!newComptroller.isComptroller()) revert MarkerMethodErr(); // Ensure invoke comptroller.isComptroller() returns true
        comptroller = newComptroller;
        emit NewComptroller(oldComptroller, newComptroller);
    }

    function setInterestRateModelFresh(IInterestRateModel newInterestRateModel) internal {
        if (accrualBlockNumber != block.number) {
            revert MarketBlockNumberNotEqCurrentBlockNumber();
        }

        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        if (!newInterestRateModel.isInterestRateModel()) revert MarkerMethodErr();

        emit NewMarketInterestRateModel(interestRateModel, newInterestRateModel);
        interestRateModel = newInterestRateModel;
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view returns (uint256) {
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint256 totalCash = underlying.balanceOf(address(this));
            uint256 cashPlusBorrowsMinusReserves = totalCash + totalBorrows - totalReserves;
            return cashPlusBorrowsMinusReserves * EXP_SCALE / _totalSupply;
        }
    }

    function accrueInterest() public {
        /* Remember the initial block number */
        uint256 currentBlockNumber = block.number;
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return;
        }

        /* Read the previous values out of storage */
        uint256 cashPrior = underlying.balanceOf(address(this));
        uint256 borrowsPrior = totalBorrows;
        uint256 reservesPrior = totalReserves;
        uint256 borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        if (borrowRateMantissa > borrowRateMaxMantissa) revert BorrowRateVHigh();

        /* Calculate the number of blocks elapsed since the last accrual */
        uint256 blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor = mul_(Exp({mantissa: borrowRateMantissa}), blockDelta);
        uint256 interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, borrowsPrior);
        uint256 totalBorrowsNew = interestAccumulated + borrowsPrior;
        uint256 totalReservesNew =
            mul_ScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
        uint256 borrowIndexNew = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);

        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);
    }

    function mintFresh(address minter, uint256 mintAmount) internal {
        /* Fail if mint not allowed */
        uint256 allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
        if (allowed != 0) {
            revert ComptrollerRejection();
        }

        /* Verify market's block number equals current block number */
        //
        if (accrualBlockNumber != block.number) {
            revert MarketBlockNumberNotEqCurrentBlockNumber();
        }

        Exp memory exchangeRate = Exp({mantissa: exchangeRateStored()});

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         *  We call `doTransferIn` for the minter and the mintAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
         *  of cash.
         */
        uint256 actualMintAmount = doTransferIn(minter, mintAmount);

        /*
         * We get the current exchange rate and calculate the number of cTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        uint256 mintTokens = div_(actualMintAmount, exchangeRate);

        /*
         * Mint cTokens to minter
         */
        _mint(minter, mintTokens);
        emit Mint(minter, actualMintAmount, mintTokens);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint256) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        uint256 principalTimesIndex = borrowSnapshot.principal * borrowIndex;
        return principalTimesIndex / borrowSnapshot.interestIndex;
    }

    /**
     * @notice Users borrow assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function borrowFresh(address payable borrower, uint256 borrowAmount) internal {
        /* Fail if borrow not allowed */
        uint256 allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
        if (allowed != 0) {
            revert ComptrollerRejection();
        }

        /* Verify market's block number equals current block number i.e. interest has been accrued*/
        if (accrualBlockNumber != block.number) {
            revert MarketBlockNumberNotEqCurrentBlockNumber();
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        if (underlying.balanceOf(address(this)) < borrowAmount) {
            revert BorrowCashNotAvailable();
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowNew = accountBorrow + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint256 accountBorrowsPrev = borrowBalanceStoredInternal(borrower);
        uint256 accountBorrowsNew = accountBorrowsPrev + borrowAmount;
        uint256 totalBorrowsNew = totalBorrows + borrowAmount;

        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing increased borrow before external transfer.
        `*/
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        /*
         * We invoke doTransferOut for the borrower and the borrowAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(borrower, borrowAmount);

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);
    }

    function doTransferIn(address from, uint256 amount) internal virtual returns (uint256) {
        uint256 balanceBefore = underlying.balanceOf(address(this));
        SafeTransferLib.safeTransferFrom(underlying, from, address(this), amount);
        uint256 balanceAfter = underlying.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    function doTransferOut(address payable to, uint amount)  internal virtual {
        SafeTransferLib.safeTransfer(underlying, to, amount);
    }

    function mint(uint256 _mintAmount) external override {
        accrueInterest();
        mintFresh(msg.sender, _mintAmount);
    }

    function borrow(uint256 borrowAmount) external override {
        accrueInterest();
        borrowFresh(payable(msg.sender), borrowAmount);
    }
}
