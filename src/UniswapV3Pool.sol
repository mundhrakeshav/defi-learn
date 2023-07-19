// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Tick} from "./lib/Tick.sol";
import {Position} from "./lib/Position.sol";
import {TickBitmap} from "./lib/TickBitmap.sol";
import {Math} from "./lib/Math.sol";
import {Position} from "./lib/Position.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUniswapV3MintCallback} from "./interfaces/IUniswapV3MintCallback.sol";
import {IUniswapV3SwapCallback} from "./interfaces/IUniswapV3SwapCallback.sol";
import {SwapMath} from "./lib/SwapMath.sol";
import {Tick} from "./lib/Tick.sol";
import {TickBitmap} from "./lib/TickBitmap.sol";
import {TickMath} from "./lib/TickMath.sol";

contract UniswapV3Pool {
    // [log_1.0001(2^−128), log_1.0001(2^128)]=[−887272,887272]
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;

    // Pool tokens, immutable
    address public immutable token0;
    address public immutable token1;

    // Packing variables that are read together
    struct Slot0 {
        // Current sqrt(P)
        uint160 sqrtPriceX96;
        // Current tick
        int24 tick;
    }

    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }

    struct SwapState {
        uint256 amountSpecifiedRemaining;
        uint256 amountCalculated;
        uint160 sqrtPriceX96;
        int24 tick;
    }

    struct StepState {
        uint160 sqrtPriceStartX96;
        int24 nextTick;
        uint160 sqrtPriceNextX96;
        uint256 amountIn;
        uint256 amountOut;
    }

    Slot0 public slot0;

    // Amount of liquidity, L.
    uint128 public liquidity;

    // Ticks info: Stores info about liquidity in various price ranges for whole pool.
    mapping(int24 => Tick.Info) public ticks;

    // Positions info: Stores info about liquidity in various price ranges provided by a user.
    // keccak256(_owner, _lowerTick, _upperTick) => Position.Info
    mapping(bytes32 => Position.Info) public positions;

    mapping(int16 => uint256) public tickBitmap;

    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();

    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 _amt0,
        uint256 _amt1
    );

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 _amt0,
        int256 _amt1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    constructor(address _token0, address _token1, uint160 _sqrtPriceX96, int24 _tick) {
        token0 = _token0;
        token1 = _token1;
        slot0 = Slot0({sqrtPriceX96: _sqrtPriceX96, tick: _tick});
    }

    // Owner’s address, to track the owner of the liquidity.
    // Upper and lower ticks, to set the bounds of a price range.
    // The amount of liquidity we want to provide.
    function mint(address _owner, int24 _lowerTick, int24 _upperTick, uint128 _amount, bytes calldata _data)
        external
        returns (uint256 _amount0, uint256 _amount1)
    {
        if (_lowerTick >= _upperTick || _lowerTick < MIN_TICK || _upperTick > MAX_TICK) revert InvalidTickRange();
        if (_amount == 0) revert ZeroLiquidity();
        //
        // Initializes a tick if it had 0 liquidity and adds new liquidity to it.
        // We’re calling update function on both lower and upper ticks, thus liquidity is added to both of them. \
        // We don't update all the ticks in between.
        bool _flippedLower = Tick.update(ticks, _lowerTick, _amount);
        bool _flippedUpper = Tick.update(ticks, _upperTick, _amount);

        if (_flippedLower) {
            TickBitmap.flipTick(tickBitmap, _lowerTick, 1);
        }
        if (_flippedUpper) {
            TickBitmap.flipTick(tickBitmap, _upperTick, 1);
        }
        //
        // Updates the user position
        Position.Info storage position = Position.get(positions, _owner, _lowerTick, _upperTick);
        Position.update(position, _amount);

        _amount0 = Math.calcAmount0Delta(
            TickMath.getSqrtRatioAtTick(slot0.tick), TickMath.getSqrtRatioAtTick(_upperTick), _amount
        );

        _amount1 = Math.calcAmount1Delta(
            TickMath.getSqrtRatioAtTick(slot0.tick), TickMath.getSqrtRatioAtTick(_lowerTick), _amount
        );

        liquidity += uint128(_amount);

        uint256 balance0Before;
        uint256 balance1Before;
        if (_amount0 > 0) balance0Before = balance0();
        if (_amount1 > 0) balance1Before = balance1();
        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(_amount0, _amount1, _data);
        if (_amount0 > 0 && balance0Before + _amount0 > balance0()) {
            revert InsufficientInputAmount();
        }
        if (_amount1 > 0 && balance1Before + _amount1 > balance1()) {
            revert InsufficientInputAmount();
        }
        emit Mint(msg.sender, _owner, _lowerTick, _upperTick, _amount, _amount0, _amount1);
    }

    function swap(address _recipient, bool _zeroForOne, uint256 _amountSpecified, bytes calldata _data)
        public
        returns (int256 _amt0, int256 _amt1)
    {
        SwapState memory _state = SwapState({
            amountSpecifiedRemaining: _amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: slot0.sqrtPriceX96,
            tick: slot0.tick
        });
        while (_state.amountSpecifiedRemaining > 0) {
            StepState memory step;

            step.sqrtPriceStartX96 = _state.sqrtPriceX96;

            (step.nextTick,) = TickBitmap.nextInitializedTickWithinOneWord(tickBitmap, _state.tick, 1, _zeroForOne);

            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.nextTick);

            (_state.sqrtPriceX96, step.amountIn, step.amountOut) = SwapMath.computeSwapStep(
                step.sqrtPriceStartX96, step.sqrtPriceNextX96, liquidity, _state.amountSpecifiedRemaining
            );

            _state.amountSpecifiedRemaining -= step.amountIn;
            _state.amountCalculated += step.amountOut;
            _state.tick = TickMath.getTickAtSqrtRatio(_state.sqrtPriceX96);
        }
        if (_state.tick != slot0.tick) {
            (slot0.sqrtPriceX96, slot0.tick) = (_state.sqrtPriceX96, _state.tick);
        }

        (_amt0, _amt1) = _zeroForOne
            ? (int256(_amountSpecified - _state.amountSpecifiedRemaining), -int256(_state.amountCalculated))
            : (-int256(_state.amountCalculated), int256(_amountSpecified - _state.amountSpecifiedRemaining));

        if (_zeroForOne) {
            IERC20(token1).transfer(_recipient, uint256(-_amt1));

            uint256 balance0Before = balance0();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(_amt0, _amt1, _data);
            if (balance0Before + uint256(_amt0) > balance0()) {
                revert InsufficientInputAmount();
            }
        } else {
            IERC20(token0).transfer(_recipient, uint256(-_amt0));

            uint256 balance1Before = balance1();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(_amt0, _amt1, _data);
            if (balance1Before + uint256(_amt1) > balance1()) {
                revert InsufficientInputAmount();
            }
        }

        emit Swap(msg.sender, _recipient, _amt0, _amt1, slot0.sqrtPriceX96, liquidity, slot0.tick);
    }

    function balance0() internal returns (uint256 balance) {
        balance = IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal returns (uint256 balance) {
        balance = IERC20(token1).balanceOf(address(this));
    }
}
