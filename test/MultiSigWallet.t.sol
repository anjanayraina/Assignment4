// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;

    function setUp() public {
        address[] memory owners = new address[](2);
        owners[0] = address(0x123);
        owners[1] = address(0xabc);
        uint256 minConfirmations = 2;
        wallet = new MultiSigWallet(owners, minConfirmations);
    }

    function testMinConfirmations() public {
        assertEq(wallet.minNumberConfirmationsRequired(), 2);
    }

    function testAddOwner() public {
        address newOwner = address(0xdef);
        wallet.addOwner(newOwner);
        assertTrue(wallet.hasRole(wallet.OWNER_ROLE(), newOwner));
    }
}
