// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWalletHarness} from "./MultiSigWalletHarness.sol";

contract MultiSigWalletInternalTests is Test {
    MultiSigWalletHarness public wallet;

    error NotEnoughConfirmations();
    error AlreadyConfirmed();

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = address(0x123);
        owners[1] = address(0xabc);
        owners[2] = address(0x456);
        uint256 minConfirmations = 2;
        vm.deal(address(this), 1000 ether);
        wallet = new MultiSigWalletHarness(owners, minConfirmations , address(this));
        (bool success,) = payable(wallet).call{value: 200 ether}("");
        require(success);
    }

    function testMinConfirmations() public {
        assertEq(wallet.minNumberConfirmationsRequired(), 2);
    }

    function test_MinConfirmationsDone() public {
        address recipient = address(0x456);
        uint256 value = 10 ether;
        vm.startPrank(address(0x123));
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        MultiSigWalletHarness.Transaction memory transaction = wallet.getTransaction(txHash);
        assertTrue(txHash != bytes32(0));
        assertEq(transaction.to, recipient);
        assertEq(transaction.value, value);
        assertEq(transaction.executed, false);
        assertFalse(wallet.minConfirmationsDone(txHash));
        vm.stopPrank();
    }
}
