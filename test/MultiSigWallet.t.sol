// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;

    error NotEnoughConfirmations();
    error AlreadyConfirmed();
    error TransactionAlreayExecuted();
    error NullAddressNotAllowed();
    error NotConfirmed();
    error InvalidTransaction();

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = address(0x123);
        owners[1] = address(0xabc);
        owners[2] = address(0x456);
        uint256 minConfirmations = 2;
        vm.deal(address(this), 1000 ether);
        wallet = new MultiSigWallet(owners, minConfirmations , address(this));
        (bool success,) = payable(wallet).call{value: 200 ether}("");
        require(success);
    }

    function test_MinConfirmations() public {
        assertEq(wallet.minNumberConfirmationsRequired(), 2);
    }

    function test_AddOwner() public {
        address newOwner = address(0xdef);
        wallet.addOwner(newOwner);
        assertTrue(wallet.hasRole(wallet.OWNER_ROLE(), newOwner));
    }

    function test_AddOwnerNullAddress() public {
        address newOwner = address(0);
        vm.expectRevert(NullAddressNotAllowed.selector);
        wallet.addOwner(newOwner);
    }

    function test_RemoveOwner() public {
        address newOwner = address(0xdef);
        wallet.addOwner(newOwner);
        assertTrue(wallet.hasRole(wallet.OWNER_ROLE(), newOwner));
        vm.startPrank(address(this));
        wallet.removeOwner(newOwner);
        assertFalse(wallet.hasRole(wallet.OWNER_ROLE(), newOwner));
    }

    function test_SubmitTransaction() public {
        address recipient = address(0x456);
        uint256 value = 10 ether;
        vm.startPrank(address(0x123));
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        MultiSigWallet.Transaction memory transaction = wallet.getTransaction(txHash);
        assertTrue(txHash != bytes32(0));
        assertEq(transaction.to, recipient);
        assertEq(transaction.value, value);
        assertEq(transaction.executed, false);
        vm.stopPrank();
    }

    function test_SubmitTransactionZeroValue() public {
        address recipient = address(0x456);
        uint256 value = 0;
        vm.startPrank(address(0x123));
        vm.expectRevert(InvalidTransaction.selector);
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        vm.stopPrank();
    }

    function test_SubmitTransactionZeroAddress() public {
        address recipient = address(0);
        uint256 value = 10 ether;
        vm.startPrank(address(0x123));
        vm.expectRevert(InvalidTransaction.selector);
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        vm.stopPrank();
    }

    function test_ConfirmTransaction() public {
        address recipient = address(0x789);
        vm.startPrank(address(0x123));
        uint256 value = 20 ether;
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        wallet.confirmTransaction(txHash);
        vm.stopPrank();
        vm.prank(address(0xabc));
        wallet.confirmTransaction(txHash);
        vm.prank(address(0x456));
        wallet.confirmTransaction(txHash);
        assertTrue(wallet.isConfirmed(txHash, address(0xabc)));
        assertTrue(wallet.isConfirmed(txHash, address(0x456)));
        assertTrue(wallet.isConfirmed(txHash, address(0x123)));
    }

    function test_AlreadyConfirmedTransaction() public {
        address recipient = address(0x789);
        vm.startPrank(address(0x123));
        uint256 value = 20 ether;
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        wallet.confirmTransaction(txHash);
        vm.stopPrank();
        vm.prank(address(0xabc));
        wallet.confirmTransaction(txHash);
        vm.startPrank(address(0x456));
        wallet.confirmTransaction(txHash);
        vm.expectRevert(AlreadyConfirmed.selector);
        wallet.confirmTransaction(txHash);
        vm.stopPrank();
    }

    function test_CancelTransaction() public {
        address recipient = address(0x789);
        vm.startPrank(address(0x123));
        uint256 value = 20 ether;
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        wallet.confirmTransaction(txHash);
        vm.stopPrank();
        vm.prank(address(0xabc));
        wallet.confirmTransaction(txHash);
        vm.startPrank(address(0x456));
        wallet.confirmTransaction(txHash);
        assertTrue(wallet.isConfirmed(txHash, address(0xabc)));
        assertTrue(wallet.isConfirmed(txHash, address(0x456)));
        assertTrue(wallet.isConfirmed(txHash, address(0x123)));
        wallet.cancelTransaction(txHash);
        assertFalse(wallet.isConfirmed(txHash, address(0x456)));
        vm.stopPrank();
    }

    function test_CancelTransactionNotConfirmed() public {
        address recipient = address(0x789);
        vm.startPrank(address(0x123));
        uint256 value = 20 ether;
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        wallet.confirmTransaction(txHash);
        vm.stopPrank();
        vm.prank(address(0xabc));
        wallet.confirmTransaction(txHash);
        vm.startPrank(address(0x456));
        vm.expectRevert(NotConfirmed.selector);
        wallet.cancelTransaction(txHash);

        vm.stopPrank();
    }

    function test_ExecuteTransaction() public {
        address recipient = address(0x789);
        vm.startPrank(address(0x123));
        uint256 value = 20 ether;
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        wallet.confirmTransaction(txHash);
        vm.stopPrank();
        vm.prank(address(0xabc));
        wallet.confirmTransaction(txHash);
        vm.prank(address(0x456));
        wallet.confirmTransaction(txHash);
        assertTrue(wallet.isConfirmed(txHash, address(0xabc)));
        assertTrue(wallet.isConfirmed(txHash, address(0x456)));
        assertTrue(wallet.isConfirmed(txHash, address(0x123)));
        vm.prank(address(0x456));
        wallet.executeTransaction(txHash);
        assertEq(address(0x789).balance, 20 ether);
    }

    function test_ExecuteTransactionAlreadyExecuted() public {
        address recipient = address(0x789);
        vm.startPrank(address(0x123));
        uint256 value = 20 ether;
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        wallet.confirmTransaction(txHash);
        vm.stopPrank();
        vm.prank(address(0xabc));
        wallet.confirmTransaction(txHash);
        vm.prank(address(0x456));
        wallet.confirmTransaction(txHash);
        assertTrue(wallet.isConfirmed(txHash, address(0xabc)));
        assertTrue(wallet.isConfirmed(txHash, address(0x456)));
        assertTrue(wallet.isConfirmed(txHash, address(0x123)));
        vm.startPrank(address(0x456));
        wallet.executeTransaction(txHash);
        vm.expectRevert(TransactionAlreayExecuted.selector);
        wallet.executeTransaction(txHash);
        vm.stopPrank();
    }

    function test_ExecuteTransactionBatch() public {
        address recipient1 = address(0x789);
        address recipient2 = address(1);
        vm.startPrank(address(0x123));
        uint256 value = 20 ether;
        bytes32 txHash1 = wallet.submitTransaction(recipient1, value);
        wallet.confirmTransaction(txHash1);
        vm.stopPrank();
        vm.startPrank(address(0x123));
        bytes32 txHash2 = wallet.submitTransaction(recipient2, value);
        wallet.confirmTransaction(txHash2);
        vm.stopPrank();
        vm.startPrank(address(0xabc));
        wallet.confirmTransaction(txHash1);
        wallet.confirmTransaction(txHash2);
        vm.stopPrank();
        vm.startPrank(address(0x456));
        wallet.confirmTransaction(txHash1);
        wallet.confirmTransaction(txHash2);
        vm.stopPrank();
        assertTrue(wallet.isConfirmed(txHash1, address(0xabc)));
        assertTrue(wallet.isConfirmed(txHash1, address(0x456)));
        assertTrue(wallet.isConfirmed(txHash1, address(0x123)));
        assertTrue(wallet.isConfirmed(txHash2, address(0xabc)));
        assertTrue(wallet.isConfirmed(txHash2, address(0x456)));
        assertTrue(wallet.isConfirmed(txHash2, address(0x123)));
        vm.startPrank(address(0x456));
        bytes32[] memory bytesArray = new bytes32[](2);
        bytesArray[0] = txHash1;
        bytesArray[1] = txHash2;
        wallet.executeBatchTransactions(bytesArray);
        assertEq(recipient1.balance, 20 ether);
        assertEq(recipient2.balance, 20 ether);
    }

    function test_ExecuteTransactionLessConfirmations() public {
        address recipient = address(0x789);
        vm.startPrank(address(0x123));
        uint256 value = 20 ether;
        bytes32 txHash = wallet.submitTransaction(recipient, value);
        wallet.confirmTransaction(txHash);
        vm.stopPrank();
        vm.prank(address(0x456));
        vm.expectRevert(NotEnoughConfirmations.selector);
        wallet.executeTransaction(txHash);
    }
}
