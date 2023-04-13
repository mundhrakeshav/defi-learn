// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CERC20Storage} from "./CERC20Storage.sol";
import {IComptroller} from "../interfaces/IComptroller.sol";
import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";
import {ExponentialNoError} from "../ExponentialNoError.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
//! No onlyAdmin protection

contract CERC20 is CERC20Storage, ExponentialNoError {
    function initialize(
        address _underlying,
        IComptroller _comptroller,
        IInterestRateModel _interestRateModel,
        uint256 _initialExchangeRateMantissa,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        if (accrualBlockNumber != 0 || borrowIndex != 0) revert AlreadyInitialized();
        if (_initialExchangeRateMantissa <= 0) revert InitialExchangeRateTooLow();

        initialExchangeRateMantissa = _initialExchangeRateMantissa;
        setComptroller(_comptroller);

        accrualBlockNumber = block.number;
        borrowIndex = MANTISSA_ONE;

        setInterestRateModelFresh(_interestRateModel);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
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

}
