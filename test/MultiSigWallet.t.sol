// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;

    error NotEnoughConfirmations();
    error AlreadyConfirmed();

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

    function testMinConfirmations() public {
        assertEq(wallet.minNumberConfirmationsRequired(), 2);
    }

    function testAddOwner() public {
        address newOwner = address(0xdef);
        wallet.addOwner(newOwner);
        assertTrue(wallet.hasRole(wallet.OWNER_ROLE(), newOwner));
    }

    function test_RemoveOwner() public {
        address newOwner = address(0xdef);
        wallet.addOwner(newOwner);
        assertTrue(wallet.hasRole(wallet.OWNER_ROLE(), newOwner));
        vm.startPrank(address(this));
        wallet.removeOwner(newOwner);
        assertFalse(wallet.hasRole(wallet.OWNER_ROLE() , newOwner));
    }

    function testSubmitTransaction() public {
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

    function testConfirmTransaction() public {
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

    function testExecuteTransaction() public {
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
