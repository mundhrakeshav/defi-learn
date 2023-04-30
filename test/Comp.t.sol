// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BaseForkedTest} from "./BaseForked.t.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ICERC20} from "src/interfaces/ICERC20.sol";

contract CompTest is BaseForkedTest {
    using stdStorage for StdStorage;

    ICERC20 public cerc;
    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function setUp() public override {
        super.setUp();
        cerc = ICERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        stdstore.target(address(DAI)).sig(DAI.balanceOf.selector).with_key(address(this)).checked_write(1 << 128);
    }

    function testMint() public {
        DAI.approve(address(cerc), 1 << 128);
        cerc.mint(100);
        // counter.increment();
        // assertEq(counter.number(), 1);

        //   [169966] CompTest::testMint()
        //     ├─ [24514] 0x6B175474E89094C44Da98b954EedeAC495271d0F::approve(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, 340282366920938463463374607431768211456)
        //     │   ├─ emit Approval(param0: CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], param1: 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, param2: 340282366920938463463374607431768211456)
        //     │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000001
        //     │
        //     │       //! 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643 => CERC20Delegator
        //     │       //! 0x3363BAe2Fc44dA742Df13CD3ee94b6bB868ea376 => CERC20Delegate
        //     │       //! 0x6B175474E89094C44Da98b954EedeAC495271d0F => DAI
        //     │
        //     ├─ [137279] 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643::mint(100)
        //     │   ├─ [131353] 0x3363BAe2Fc44dA742Df13CD3ee94b6bB868ea376::mint(100) [delegatecall]
        //     │   │   ├─ [2602] 0x6B175474E89094C44Da98b954EedeAC495271d0F::balanceOf(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643) [staticcall]
        //     │   │   │   └─ ← 0x000000000000000000000000000000000000000000a7d2b99e65df3169fb39da // [202885732898473567902710234]
        //     │   │   ├─ [7758] 0xFB564da37B41b2F6B6EDcc3e56FbF523bD9F2012::getBorrowRate(202885732898473567902710234, 191195813820371530643685684, 21787777933631719573690461) [staticcall]
        //     │   │   │   └─ ← 0x00000000000000000000000000000000000000000000000000000002d7fe47d2
        //     │   │   ├─ emit AccrueInterest(: 202885732898473567902710234, : 833669405479441129721, : 1167510257805146209, : 191196647489777010084815405)
        //     │   │   ├─ [57471] 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B::mintAllowed(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 100)
        //     │   │   │   ├─ [52291] 0xBafE01ff935C7305907c33BF824352eE5979B526::mintAllowed(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 100) [delegatecall]
        //     │   │   │   │   ├─ [2344] 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643::totalSupply() [staticcall]
        //     │   │   │   │   │   └─ ← 0x00000000000000000000000000000000000000000000000017437cc0f0cb4c91
        //     │   │   │   │   ├─ [6773] 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643::balanceOf(CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
        //     │   │   │   │   │   ├─ [4257] 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643::delegateToImplementation(0x70a082310000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496) [staticcall]
        //     │   │   │   │   │   │   ├─ [2600] 0x3363BAe2Fc44dA742Df13CD3ee94b6bB868ea376::balanceOf(CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [delegatecall]
        //     │   │   │   │   │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
        //     │   │   │   │   │   │   └─ ← 0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000
        //     │   │   │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
        //     │   │   │   │   ├─ emit DistributedSupplierComp(param0: 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, param1: CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], param2: 0, param3: 86508784270234988782896552563600702527935)
        //     │   │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
        //     │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
        //     │   │   ├─ [602] 0x6B175474E89094C44Da98b954EedeAC495271d0F::balanceOf(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643) [staticcall]
        //     │   │   │   └─ ← 0x000000000000000000000000000000000000000000a7d2b99e65df3169fb39da
        //     │   │   ├─ [602] 0x6B175474E89094C44Da98b954EedeAC495271d0F::balanceOf(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643) [staticcall]
        //     │   │   │   └─ ← 0x000000000000000000000000000000000000000000a7d2b99e65df3169fb39da
        //     │   │   ├─ [12375] 0x6B175474E89094C44Da98b954EedeAC495271d0F::transferFrom(CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, 100)
        //     │   │   │   ├─ emit Transfer(param0: CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], param1: 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, param2: 100)
        //     │   │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000001
        //     │   │   ├─ [602] 0x6B175474E89094C44Da98b954EedeAC495271d0F::balanceOf(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643) [staticcall]
        //     │   │   │   └─ ← 0x000000000000000000000000000000000000000000a7d2b99e65df3169fb3a3e
        //     │   │   ├─ emit Mint(: CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], : 100, : 0)
        //     │   │   ├─ emit Transfer(param0: 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, param1: CompTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], param2: 0)
        //     │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
        //     │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
        //     └─ ← ()
    }
}
