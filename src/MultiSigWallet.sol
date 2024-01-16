// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title MultiSignature Wallet
 * @author Anjanay Raina 
 * @notice This contract allows multiple owners to collectively control the funds in the wallet.
 */
contract MultiSigWallet {
  // List of owners
  address[] public owners;
  // Number of confirmations required to execute a transaction
  uint public numConfirm;

  /**
   * @notice Represents a transaction.
   * @param to The recipient of the transaction.
   * @param value The amount of Ether in the transaction.
   * @param executed Whether the transaction has been executed.
   */
  struct Transaction {
      address to;
      uint value;
      bool executed;
  }

  // Map of transaction IDs to maps of owners to boolean values indicating whether they have confirmed the transaction
  mapping (uint => mapping (address => bool)) isConfirmed;
  // Map of owners to booleans indicating whether they are owners
  mapping (address => bool) isOwner;

  // Array of all transactions
  Transaction[] public transactions;

  // Custom errors
  error NotAnOwner();
  error InvalidOwner();
  error InvalidTransaction();
  error AlreadyConfirmed();
  error ExecutionFailed();

  /**
   * @notice Emitted when a transaction is submitted.
   * @param transactionId The ID of the transaction.
   * @param sender The sender of the transaction.
   * @param receiver The receiver of the transaction.
   * @param amount The amount of the transaction.
   */
  event TransactionSubmitted(uint transactionId, address sender, address receiver, uint amount);

  /**
   * @notice Emitted when a transaction is confirmed.
   * @param transactionId The ID of the transaction.
   */
  event TransactionConfirmed(uint transactionId);

  /**
   * @notice Emitted when a transaction is executed.
   * @param transactionId The ID of the transaction.
   */
  event TransactionExecuted(uint transactionId);

  /**
   * @notice Modifier to restrict function calls to owners only.
   */
  modifier onlyOwner() {
      if (!isOwner[msg.sender]) revert NotAnOwner();
      _;
  }

  /**
   * @notice Constructor for the MultiSigWallet contract.
   * @param _owners The initial owners of the wallet.
   * @param _numConfirmationRequired The number of confirmations required to execute a transaction.
   */
  constructor(address[] memory _owners, uint _numConfirmationRequired) {
      if (_owners.length <= 1) revert InvalidOwner();
      if (_numConfirmationRequired == 0 || _numConfirmationRequired > _owners.length) revert InvalidOwner();
      numConfirm = _numConfirmationRequired;

      for(uint i = 0; i < _owners.length; i++) {
          if (_owners[i] == address(0)) revert InvalidOwner();
          owners.push(_owners[i]);
          isOwner[_owners[i]] = true;
      }
  }

  /**
   * @notice Submits a new transaction.
   * @param _to The recipient of the transaction.
   */
  function submitTransaction(address _to) public payable onlyOwner {
      if (_to == address(0)) revert InvalidTransaction();
      if (msg.value == 0) revert InvalidTransaction();
      uint transactionId = transactions.length;

      transactions.push(Transaction({
          to: _to,
          value: msg.value,
          executed: false
      }));

      emit TransactionSubmitted(transactionId, msg.sender, _to, msg.value);
  }


}
