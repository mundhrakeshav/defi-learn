// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/safe/SafeConfig.sol";
import "../src/safe/GnosisSafe/GnosisSafe.sol";

contract SafeTest is Test, SafeConfig {
    address owner1;
    address owner2;

    function setUp() public {
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
    }
    // address[] calldata _owners,
    // uint256 _threshold,
    // address to,
    // bytes calldata data,
    // address fallbackHandler,
    // address paymentToken,
    // uint256 payment,
    // address payable paymentReceiver

    // 0xb63e800d
    // 0000000000000000000000000000000000000000000000000000000000000100
    // 0000000000000000000000000000000000000000000000000000000000000001
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000140
    // 000000000000000000000000f48f2b2d2a534e402487b3ee7c18c33aec0fe5e4
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000000
    // 0000000000000000000000000000000000000000000000000000000000000001
    // 000000000000000000000000f0c3f4a45ff4cd5c87c6e05eb044c1a3353423e6
    // 0000000000000000000000000000000000000000000000000000000000000000

    // _owners = ["0xf0c3f4a45ff4cd5c87c6e05eb044c1a3353423e6"],
    // _threshold = 1,
    // to = 0x0000000000000000000000000000000000000000,
    // data = 0x,
    // fallbackHandler = 0xf48f2b2d2a534e402487b3ee7c18c33aec0fe5e4,
    // paymentToken = 0x0000000000000000000000000000000000000000,
    // payment = 0,
    // paymentReceiver = 0x0000000000000000000000000000000000000000

    function testProxyDeployment() public {
        address[] memory _owners = new address[](2);
        _owners[0] = owner1;
        _owners[1] = owner2;
        bytes memory _data = new bytes(0x00);
        bytes memory _initializer = abi.encodeCall(GnosisSafe.setup, (_owners, 1, address(0), _data, address(0), address(0), 0, payable(0)));
        // safeFactory.createProxyWithNonce(safeSingletonAddress, initializer, saltNonce);
        console.logBytes(_initializer);

    }
}
