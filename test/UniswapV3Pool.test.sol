// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Test} from "forge-std/Test.sol";
import {ERC20Mintable} from "./ERC20Mintable.sol";
import {TestUtils} from "./TestUtils.sol";
import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract UniswapV3PoolTest is Test, TestUtils {
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;

    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;
    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }

    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        int24 currentTick;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        uint160 currentSqrtP;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiqudity;
    }

    function testMintSuccess() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether, // WETH amt to mint
            usdcBalance: 5000 ether, // USDC amt to mint
            currentTick: 85176, // Tick to start pool at
            lowerTick: 84222, // LowerTick in range to provide liquidity in
            upperTick: 86129, // UpperTick in range to provide liquidity in
            liquidity: 1517882343751509868544, // Amt of liquidity to provide
            currentSqrtP: 5602277097478614198912276234240, // Current sqrt(price), price to start pool at
            transferInMintCallback: true, //Bool: should transfer on mint callback
            transferInSwapCallback: true, //Bool: should transfer on swap callback
            mintLiqudity: true // Bool: should mint liquidity and add tokens to pool
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 expectedAmount0 = 0.998833192822975409 ether;
        uint256 expectedAmount1 = 4999.187247111820044641 ether;
        // Verify returned amt
        assertEq(poolBalance0, expectedAmount0, "incorrect token0 deposited amount");
        assertEq(poolBalance1, expectedAmount1, "incorrect token1 deposited amount");
        // Verify token balance
        assertEq(token0.balanceOf(address(pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(pool)), expectedAmount1);
        // Verify user position
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), params.lowerTick, params.upperTick));
        uint128 posLiquidity = pool.positions(positionKey);
        assertEq(posLiquidity, params.liquidity);
        // Verify ticks
        (bool tickInitialized, uint128 tickLiquidity) = pool.ticks(params.lowerTick);
        assertTrue(tickInitialized);
        assertEq(tickLiquidity, params.liquidity);

        (tickInitialized, tickLiquidity) = pool.ticks(params.upperTick);
        assertTrue(tickInitialized);
        assertEq(tickLiquidity, params.liquidity);

        // Verify current price and ticks
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, 5602277097478614198912276234240, "invalid current sqrtP");
        assertEq(tick, 85176, "invalid current tick");
        assertEq(pool.liquidity(), 1517882343751509868544, "invalid current liquidity");
    }

    function testMintInvalidTickRangeLower() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );

        vm.expectRevert(encodeError("InvalidTickRange()"));
        pool.mint(address(this), MIN_TICK - 1, 0, 0, "");
    }

    function testMintInvalidTickRangeUpper() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );

        vm.expectRevert(encodeError("InvalidTickRange()"));
        pool.mint(address(this), 0, MAX_TICK + 1, 0, "");
    }

    function testMintZeroLiquidity() public {
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            uint160(1),
            0
        );

        vm.expectRevert(encodeError("ZeroLiquidity()"));
        pool.mint(address(this), 0, 1, 0, "");
    }

    function testMintInsufficientTokenBalance() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 0,
            usdcBalance: 0,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            transferInMintCallback: false,
            transferInSwapCallback: true,
            mintLiqudity: false
        });
        setupTestCase(params);

        vm.expectRevert(encodeError("InsufficientInputAmount()"));
        pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity, "");
    }

    function testSwapBuyEth() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            transferInMintCallback: true,
            transferInSwapCallback: true, //Bool: should transfer on swap callback
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 swapAmount = 42 ether; // 42 USDC
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        UniswapV3Pool.CallbackData memory extra =
            UniswapV3Pool.CallbackData({token0: address(token0), token1: address(token1), payer: address(this)});

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) = pool.swap(address(this), false, swapAmount, abi.encode(extra));

        assertEq(amount0Delta, -0.008396714242162445 ether, "invalid ETH out");
        assertEq(amount1Delta, 42 ether, "invalid USDC in");
        assertEq(
            token0.balanceOf(address(this)), uint256(userBalance0Before + (-amount0Delta)), "invalid user ETH balance"
        );
        assertEq(
            token1.balanceOf(address(this)), uint256(userBalance1Before - amount1Delta), "invalid user USDC balance"
        );
        assertEq(
            token0.balanceOf(address(pool)), uint256(int256(poolBalance0) + amount0Delta), "invalid pool ETH balance"
        );
        assertEq(
            token1.balanceOf(address(pool)), uint256(int256(poolBalance1) + amount1Delta), "invalid pool USDC balance"
        );
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, 5604469350942327889444743441197, "invalid current sqrtP");
        assertEq(tick, 85184, "invalid current tick");
        assertEq(pool.liquidity(), 1517882343751509868544, "invalid current liquidity");
    }

    function testSwapInsufficientInputAmount() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            transferInMintCallback: true,
            transferInSwapCallback: false,
            mintLiqudity: true
        });
        setupTestCase(params);
        UniswapV3Pool.CallbackData memory extra =
            UniswapV3Pool.CallbackData({token0: address(token0), token1: address(token1), payer: address(this)});

        vm.expectRevert(encodeError("InsufficientInputAmount()"));
        (int256 amount0Delta, int256 amount1Delta) = pool.swap(address(this), false, 42 ether, abi.encode(extra));
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // INTERNAL
    //
    ////////////////////////////////////////////////////////////////////////////
    // mints given token0 and token1 amt to address(this)
    // Creates a new pool at given tick and price
    // if mintLiquidity flag is set, mints liquidity to address(this) by adding given number of tokens
    // sets other flags

    function setupTestCase(TestCaseParams memory params)
        internal
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool = new UniswapV3Pool(
        address(token0),
        address(token1),
        params.currentSqrtP,
        params.currentTick);

        UniswapV3Pool.CallbackData memory extra =
            UniswapV3Pool.CallbackData({token0: address(token0), token1: address(token1), payer: address(this)});

        if (params.mintLiqudity) {
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);
            (poolBalance0, poolBalance1) =
                pool.mint(address(this), params.lowerTick, params.upperTick, params.liquidity, abi.encode(extra));
        }

        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // CALLBACKS
    //
    ////////////////////////////////////////////////////////////////////////////
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) public {
        if (transferInMintCallback) {
            UniswapV3Pool.CallbackData memory extra = abi.decode(data, (UniswapV3Pool.CallbackData));
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
        }
    }

    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) public {
        if (transferInSwapCallback) {
            UniswapV3Pool.CallbackData memory extra = abi.decode(data, (UniswapV3Pool.CallbackData));

            if (amount0 > 0) {
                IERC20(extra.token0).transferFrom(extra.payer, msg.sender, uint256(amount0));
            }

            if (amount1 > 0) {
                IERC20(extra.token1).transferFrom(extra.payer, msg.sender, uint256(amount1));
            }
        }
    }
}
