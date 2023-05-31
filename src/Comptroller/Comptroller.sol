// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ComptrollerStorage} from "./ComptrollerStorage.sol";
import {IComptroller} from "../interfaces/IComptroller.sol";
import {ICToken} from "../interfaces/ICToken.sol";
import {IErrors} from "../interfaces/IErrors.sol";

contract Comptroller is IComptroller, IErrors, ComptrollerStorage {

    // @notice The initial COMP index for a market
    uint256 public constant INITIAL_INDEX = 1e36;

    // @notice closeFactorMantissa must be strictly greater than this value
    uint256 internal constant CLOSE_FACTOR_MIN_MANTISSA = 0.05e18; // 0.05

    // @notice closeFactorMantissa must be strictly less than this value
    uint256 internal constant CLOSE_FACTOR_MAX_MANTISSA = 0.9e18; // 0.9

    constructor() {
        admin = msg.sender;
    }

    function mintAllowed(ICToken cToken) external view override returns (bool) {
        if (!markets[cToken].isListed) {
            revert MarketNotListed();
        }
        return true;
    }

    function borrowAllowed(ICToken cToken, address borrower, uint256 borrowAmount)
        external
        view
        override
        returns (bool)
    {
        if (!markets[cToken].isListed) {
            revert MarketNotListed();
        }
        if (!markets[cToken].accountMembership[borrower]) {
            // If account is not in market only cToken can call 
            if(msg.sender != address(cToken)) revert SenderNotCToken();
            addToMarketInternal(CToken(msg.sender), borrower);

        }
        return true;
    }
}
