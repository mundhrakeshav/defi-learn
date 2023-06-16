// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC20} from "../IERC20.sol";

interface ICApe is IERC20 {
    /**
     * @return the amount of shares that corresponds to `amount` protocol-controlled Ape.
     */
    function getShareByPooledApe(uint256 amount) external view returns (uint256);

    /**
     * @return the amount of Ape that corresponds to `sharesAmount` token shares.
     */
    function getPooledApeByShares(uint256 sharesAmount) external view returns (uint256);

    /**
     * @return the amount of shares belongs to _account.
     */
    function sharesOf(address _account) external view returns (uint256);
}


interface IAutoCompoundApe is ICApe {

    /**
     * @notice deposit an `amount` of ape into compound pool.
     * @param onBehalf The address of user will receive the pool share
     * @param amount The amount of ape to be deposit
     **/
    function deposit(address onBehalf, uint256 amount) external;

    /**
     * @notice withdraw an `amount` of ape from compound pool.
     * @param amount The amount of ape to be withdraw
     **/
    function withdraw(uint256 amount) external;

    /**
     * @notice collect ape reward in ApeCoinStaking and deposit to earn compound interest.
     **/
    function harvestAndCompound() external;
}
