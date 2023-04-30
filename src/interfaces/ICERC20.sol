// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ICToken.sol";

interface ICERC20 is ICToken {
    /**
     * User Interface **
     */
    function mint(uint256 _mintAmount) external;
    // function redeem(uint redeemTokens) external returns (uint);
    // function redeemUnderlying(uint redeemAmount) external returns (uint);
    // function borrow(uint borrowAmount) external returns (uint);
    // function repayBorrow(uint repayAmount) external returns (uint);
    // function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    // function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
    // function sweepToken(address token) external;

    // /*** Admin Functions ***/
    // function addReserves(uint addAmount) external returns (uint);
}
