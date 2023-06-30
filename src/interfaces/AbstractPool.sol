// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

abstract contract AbstractPool is ERC20 {
    function setSwapFee(uint256 swapFee) external virtual;
    function setPublicSwap(bool public_) external virtual;

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external virtual;
    function joinswapExternAmountIn(address tokenIn, uint256 tokenAmountIn, uint256 minPoolAmountOut)
        external
        virtual
        returns (uint256 poolAmountOut);
    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external virtual;
    function setController(address controller) external virtual;
}
