// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MultiSigWallet} from "../../src/MultiSigWallet.sol";

contract MultiSigWalletHarness is MultiSigWallet {
    constructor(address[] memory _owners, uint256 _minNumberConfirmationsRequired, address admin)
        MultiSigWallet(_owners, _minNumberConfirmationsRequired, admin)
    {}

    function minConfirmationsDone(bytes32 transactionID) public view returns (bool) {
        return super._minConfirmationsDone(transactionID);
    }
}
