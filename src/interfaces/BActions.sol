// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BFactory} from "./BFactory.sol";
import {BPool} from "./BPool.sol";
import {CRPFactory} from "./CRPFactory.sol";
import {ConfigurableRightsPool} from "./ConfigurableRightsPool.sol";
import {RightsManager} from "./RightsManager.sol";
import {AbstractPool} from "./AbstractPool.sol";
import {Vault} from "./Vault.sol";
import {BalancerPool} from "./BalancerPool.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

abstract contract BActions {
    // --- Pool Creation ---

    function create(
        BFactory factory,
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata weights,
        uint256 swapFee,
        bool finalize
    ) external virtual returns (BPool pool);

    function createSmartPool(
        CRPFactory factory,
        BFactory bFactory,
        ConfigurableRightsPool.PoolParams calldata poolParams,
        ConfigurableRightsPool.CrpParams calldata crpParams,
        RightsManager.Rights calldata rights
    ) external virtual returns (ConfigurableRightsPool crp);

    // --- Joins ---

    function joinPool(BPool pool, uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external virtual;

    function joinSmartPool(ConfigurableRightsPool pool, uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        virtual;

    function joinswapExternAmountIn(AbstractPool pool, ERC20 token, uint256 tokenAmountIn, uint256 minPoolAmountOut)
        external
        virtual;
    // --- Pool management (common) ---

    function setPublicSwap(AbstractPool pool, bool publicSwap) external virtual;

    function setSwapFee(AbstractPool pool, uint256 newFee) external virtual;

    function setController(AbstractPool pool, address newController) external virtual;

    // --- Private pool management ---

    function setTokens(BPool pool, address[] calldata tokens, uint256[] calldata balances, uint256[] calldata denorms)
        external
        virtual;

    function finalize(BPool pool) external virtual;

    // --- Smart pool management ---

    function increaseWeight(ConfigurableRightsPool crp, ERC20 token, uint256 newWeight, uint256 tokenAmountIn)
        external
        virtual;

    function decreaseWeight(ConfigurableRightsPool crp, ERC20 token, uint256 newWeight, uint256 poolAmountIn)
        external
        virtual;

    function updateWeightsGradually(
        ConfigurableRightsPool crp,
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock
    ) external virtual;

    function setCap(ConfigurableRightsPool crp, uint256 newCap) external virtual;

    function commitAddToken(ConfigurableRightsPool crp, ERC20 token, uint256 balance, uint256 denormalizedWeight)
        external
        virtual;

    function applyAddToken(ConfigurableRightsPool crp, ERC20 token, uint256 tokenAmountIn) external virtual;

    function removeToken(ConfigurableRightsPool crp, ERC20 token, uint256 poolAmountIn) external virtual;

    function whitelistLiquidityProvider(ConfigurableRightsPool crp, address provider) external virtual;

    function removeWhitelistedLiquidityProvider(ConfigurableRightsPool crp, address provider) external virtual;

    // --- Migration ---

    function migrateProportionally(
        Vault vault,
        BPool poolIn,
        uint256 poolInAmount,
        uint256[] calldata tokenOutAmountsMin,
        BalancerPool poolOut,
        uint256 poolOutAmountMin
    ) external virtual;

    function migrateAll(
        Vault vault,
        BPool poolIn,
        uint256 poolInAmount,
        uint256[] calldata tokenOutAmountsMin,
        BalancerPool poolOut,
        uint256 poolOutAmountMin
    ) external virtual;
}
