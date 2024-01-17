// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/AccessControl.sol";

pragma solidity ^0.8.4;

/**
 * @title MultiSignature Wallet
 * @author Anjanay Raina
 * @notice This contract allows multiple owners to collectively control the funds in the wallet.
 */
contract MultiSigWallet is AccessControl {
    //
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    // Number of confirmations required to execute a transaction
    uint256 public minNumberConfirmationsRequired;
    //
    uint256 public transactionCount;
    /**
     * @notice Represents a transaction.
     * @param to The recipient of the transaction.
     * @param value The amount of Ether in the transaction.
     * @param executed Whether the transaction has been executed.
     */

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 confirmations;
    }

    // Map of transaction IDs to maps of owners to boolean values indicating whether they have confirmed the transaction
    mapping(bytes32 => mapping(address => bool)) public isConfirmed;

    // Mapping of all transactions
    mapping(bytes32 => Transaction) transactions;

    // Array of all the owners
    address[] owners;
    // Custom errors

    error NullAddressNotAllowed();
    error InvalidTransaction();
    error AlreadyConfirmed();
    error ExecutionFailed();
    error LowOwnerArrayLength();
    error InvalidMinConfirmations();
    error NotEnoughConfirmations();

    /**
     * @notice Emitted when a transaction is submitted.
     * @param transactionId The ID of the transaction.
     * @param sender The sender of the transaction.
     * @param receiver The receiver of the transaction.
     * @param amount The amount of the transaction.
     */
    event TransactionSubmitted(uint256 transactionId, address sender, address receiver, uint256 amount);

    /**
     * @notice Emitted when a transaction is confirmed.
     * @param transactionId The ID of the transaction.
     */
    event TransactionConfirmed(bytes32 transactionId);

    /**
     * @notice Emitted when a transaction is executed.
     * @param transactionId The ID of the transaction.
     */
    event TransactionExecuted(bytes32 transactionId);

    /**
     * @notice Constructor for the MultiSigWallet contract.
     * @param _owners The initial owners of the wallet.
     * @param _minNumberConfirmationsRequired The number of confirmations required to execute a transaction.
     */
    constructor(address[] memory _owners, uint256 _minNumberConfirmationsRequired, address admin) payable {
        if (_owners.length <= 1) revert LowOwnerArrayLength();
        if (_minNumberConfirmationsRequired == 0 || _minNumberConfirmationsRequired > _owners.length) {
            revert InvalidMinConfirmations();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
        minNumberConfirmationsRequired = _minNumberConfirmationsRequired;

        for (uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == address(0)) revert NullAddressNotAllowed();
            owners.push(_owners[i]);
            _grantRole(OWNER_ROLE, owners[i]);
        }
    }

    receive() external payable {}
    /**
     * @notice adds another owner of the contract
     * @param ownerAddress The address to be added in the owner array
     */

    function addOwner(address ownerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        owners.push(ownerAddress);
        _grantRole(OWNER_ROLE, ownerAddress);
    }

    function getTransaction(bytes32 transationID) public view returns (Transaction memory) {
        return transactions[transationID];
    }

    /**
     * @notice Submits a new transaction that gets added in the queue to get executed
     * @param _to The recipient of the transaction.
     * @param _value The value of the transaction .
     */
    function submitTransaction(address _to, uint256 _value) external onlyRole(OWNER_ROLE) returns (bytes32) {
        if (_to == address(0)) revert InvalidTransaction();
        if (_value == 0) revert InvalidTransaction();
        bytes32 transactionHash = bytes32(keccak256(abi.encodePacked(transactionCount, _to, _value)));
        transactions[transactionHash] = Transaction({to: _to, value: _value, executed: false, confirmations: 0});
        emit TransactionSubmitted(transactionCount, msg.sender, _to, _value);
        transactionCount++;
        return transactionHash;
    }

    /**
     * @notice Confirms a transaction for the calling owner address
     * @param transactionID The ID of the transaction to confirm.
     */
    function confirmTransaction(bytes32 transactionID) public onlyRole(OWNER_ROLE) {
        if (isConfirmed[transactionID][msg.sender]) revert AlreadyConfirmed();
        isConfirmed[transactionID][msg.sender] = true;
        transactions[transactionID].confirmations++;
        emit TransactionConfirmed(transactionID);
    }

    /**
     * @notice Checks if a transaction has enough confirmations.
     * @param transactionID The ID of the transaction to check.
     * @return Returns true if the transaction has enough confirmations, false otherwise.
     */
    function _minConfirmationsDone(bytes32 transactionID) internal view returns (bool) {
        return transactions[transactionID].confirmations >= minNumberConfirmationsRequired;
    }
    /**
     * @notice Executes the transactions if a transaction has enough confirmations.
     * @param transactionID The ID of the transaction to check.
     */

    function executeTransaction(bytes32 transactionID) public payable onlyRole(OWNER_ROLE) {
        require(!transactions[transactionID].executed, "Transaction is already executed");
        if (!_minConfirmationsDone(transactionID)) {
            revert NotEnoughConfirmations();
        }
        (bool success,) = transactions[transactionID].to.call{value: transactions[transactionID].value}("");

        require(success, "Transaction Execution Failed ");
        transactions[transactionID].executed = true;
        emit TransactionExecuted(transactionID);
    }
}
