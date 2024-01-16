// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/AccessControl.sol";
pragma solidity ^0.8.4;

/**
 * @title MultiSignature Wallet
 * @author Anjanay Raina 
 * @notice This contract allows multiple owners to collectively control the funds in the wallet.
 */
contract MultiSigWallet is AccessControl{
   
   // 
   bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  // Number of confirmations required to execute a transaction
  uint256 public minNumberConfirmationsRequired;
  // 
  uint256 transactionCount;
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
  mapping (bytes32 => mapping (address => bool)) isConfirmed;

  // Mapping of all transactions
  mapping (bytes32=>Transaction) transactions;

  // Array of all the owners
  address[] owners;
  // Custom errors
  error NullAddressNotAllowed();
  error InvalidTransaction();
  error AlreadyConfirmed();
  error ExecutionFailed();
  error LowOwnerArrayLength();
  error InvalidMinConfirmations();

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
   * @notice Constructor for the MultiSigWallet contract.
   * @param _owners The initial owners of the wallet.
   * @param _minNumberConfirmationsRequired The number of confirmations required to execute a transaction.
   */
  constructor(address[] memory _owners, uint _minNumberConfirmationsRequired) payable {
      if (_owners.length <= 1) revert LowOwnerArrayLength();
      if (_minNumberConfirmationsRequired == 0 || _minNumberConfirmationsRequired > _owners.length) revert InvalidMinConfirmations();
       _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
      minNumberConfirmationsRequired = _minNumberConfirmationsRequired;

      for(uint i = 0; i < _owners.length; i++) {
          if (_owners[i] == address(0)) revert NullAddressNotAllowed();
          owners.push(_owners[i]);
      }
  }

  fallback() external payable {

  }
/**
   * @notice adds another owner of the contract  
   * @param _to The recipient of the transaction.
   */
  function addOwner(address ownerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    owners.push(ownerAddress);
  }

  /**
   * @notice Submits a new transaction that gets added in the queue to get executed 
   * @param _to The recipient of the transaction.
   */
  function submitTransaction(address _to , uint256 _value ) external onlyRole(OWNER_ROLE) returns(bytes32){
      if (_to == address(0)) revert InvalidTransaction();
      if (msg.value == 0) revert InvalidTransaction();
      bytes32 transactionHash = bytes32(keccak256(abi.encodePacked(transactionCount , _to , _value )));
      transactions[transactionHash] = Transaction({
          to: _to,
          value: _value,
          executed: false
      });
      emit TransactionSubmitted(transactionCount, msg.sender, _to, msg.value);
      
  }

  /**
   * @notice Confirms a transaction.
   * @param _transactionId The ID of the transaction to confirm.
   */
  function confirmTransaction(uint _transactionId) public onlyRole(OWNER_ROLE) {
      if (isConfirmed[_transactionId][msg.sender]) revert AlreadyConfirmed();
      isConfirmed[_transactionId][msg.sender] = true;
      emit TransactionConfirmed(_transactionId);

      if(_isTransactionConfirmed(_transactionId)) {
          executeTransaction(_transactionId);
      }
  }

     /**
    * @notice Checks if a transaction has enough confirmations.
    * @param _transactionId The ID of the transaction to check.
    * @return Returns true if the transaction has enough confirmations, false otherwise.
    */
   function _isTransactionConfirmed(uint _transactionId) internal view returns (bool) {
       require(_transactionId < transactionCount, "Invalid transaction");
       uint confirmation;
       for(uint i = 0; i < transactions.length; i++) {
           if(isConfirmed[_transactionId][owners[i]]) {
               confirmation++;
           }
       }
       return confirmation >= minNumberConfirmationsRequired;
   }
    function executeTransaction(uint _transactionId) public payable {
        require(_transactionId<transactions.length,"Invalid transaction");
        require(!transactions[_transactionId].executed,"Transaction is already executed");
      
        (bool success,)= transactions[_transactionId].to.call{value:transactions[_transactionId].value}("");

       require(success,"Transaction Execution Failed ");
       transactions[_transactionId].executed=true;
       emit TransactionExecuted(_transactionId);
   }

}