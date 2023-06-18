// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IPool} from "./AAVE/IPool.sol";
import {IAavePriceOracle} from "./AAVE/IAavePriceOracle.sol";
import {IPoolAddressesProvider} from "./AAVE/IPoolAddressesProvider.sol";
import {IAutoCompoundApe} from "./ParaSpace/IAutoCompoundApe.sol";
import {IWETH9} from "./IWETH9.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ISwapRouter} from "./Uniswap/ISwapRouter.sol";
import {IHelperContractParaSpace} from "./IHelperContractParaSpace.sol";
import {AggregatorInterface} from "chainlink/interfaces/AggregatorInterface.sol";

contract Config {
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant APE_COIN_ADDRESS = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
    address public constant PC_APE_ADDRESS = 0xDDDe38696FBe5d11497D72d8801F651642d62353;
    address public constant C_APE_ADDRESS = 0xC5c9fB6223A989208Df27dCEE33fC59ff5c26fFF;
    //
    address public constant AAVE_POOL_ADDRESS = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant AAVE_ETH_WETH_ADDRESS = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    address public constant AAVE_VARIABLE_DEBT_USDC_ADDRESS = 0x72E95b8931767C79bA4EeE721354d6E99a61D004;
    address public constant AAVE_PRICE_ORACLE_ADDRESS = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;
    address public constant AAVE_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    address public constant AAVE_POOL_ADDRESSES_PROVIDER_ADDRESS = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    //
    address public constant HELPER_CONTRACT_PARASPACE_ADDRESS = 0xBAa0DaA4224d2eb4619FfDC8A50Ef50c754b55F3;
    address public constant POOL_APE_STAKING_ADDRESS = 0x638a98BBB92a7582d07C52ff407D49664DC8b3Ee;
    //
    address public constant SWAP_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    //
    address public constant CHAINLINK_APE_USD_AGGREGATOR_ADDRESS = 0xD10aBbC76679a20055E167BB80A24ac851b37056;
    address public constant CHAINLINK_ETH_USD_AGGREGATOR_ADDRESS = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant CHAINLINK_USDC_USD_AGGREGATOR_ADDRESS = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    //
    //
    IWETH9 public constant WETH = IWETH9(WETH_ADDRESS);
    ERC20 public constant USDC = ERC20(USDC_ADDRESS);
    ERC20 public constant DAI = ERC20(DAI_ADDRESS);
    ERC20 public constant PC_APE = ERC20(PC_APE_ADDRESS);
    //
    IPool public constant AAVE_POOL = IPool(AAVE_POOL_ADDRESS);
    IAavePriceOracle public constant AAVE_PRICE_ORACLE = IAavePriceOracle(AAVE_PRICE_ORACLE_ADDRESS);
    ERC20 public constant AAVE_ETH_WETH = ERC20(AAVE_ETH_WETH_ADDRESS);
    ERC20 public constant AAVE_VARIABLE_DEBT_USDC = ERC20(AAVE_VARIABLE_DEBT_USDC_ADDRESS);
    IPoolAddressesProvider public constant AAVE_POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(AAVE_POOL_ADDRESSES_PROVIDER_ADDRESS);
    //
    ERC20 public constant APE = ERC20(APE_COIN_ADDRESS);
    //
    ISwapRouter public constant SWAP_ROUTER = ISwapRouter(SWAP_ROUTER_ADDRESS);
    IHelperContractParaSpace public constant HELPER_CONTRACT_PARASPACE =
        IHelperContractParaSpace(HELPER_CONTRACT_PARASPACE_ADDRESS);
    IAutoCompoundApe public constant C_APE = IAutoCompoundApe(C_APE_ADDRESS);
    AggregatorInterface public constant CHAINLINK_APE_USD_AGGREGATOR =
        AggregatorInterface(CHAINLINK_APE_USD_AGGREGATOR_ADDRESS);
    AggregatorInterface public constant CHAINLINK_ETH_USD_AGGREGATOR =
        AggregatorInterface(CHAINLINK_ETH_USD_AGGREGATOR_ADDRESS);
    AggregatorInterface public constant CHAINLINK_USDC_USD_AGGREGATOR =
        AggregatorInterface(CHAINLINK_USDC_USD_AGGREGATOR_ADDRESS);
}
