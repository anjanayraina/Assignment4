// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSigWallet is Ownable {
   address[] public owners;
   uint public numConfirm;

   struct Transaction {
       address to;
       uint value;
       bool executed;
   }

   mapping (uint=>mapping (address=>bool)) isConfirmed;
   mapping (address=>bool) isOwner;

   Transaction[] public transactions;

   event TransactionSubmitted(uint transactionId,address sender,address receiver,uint amount);
   event TransactionConfirmed(uint transactionId);
   event TransactionExecuted(uint transactionId);

   constructor(address[] memory _owners,uint _numConfirmationRequired) Ownable(msg.sender){
       require(_owners.length>1,"owners required must grater than 1");
       require( _numConfirmationRequired>0 && _numConfirmationRequired<=_owners.length,"Num of confirmation is not sync with num of owner");
       numConfirm=_numConfirmationRequired;

       for(uint i=0;i<_owners.length;i++){
           require(_owners[i]!=address(0),"Invalid Owner");
           owners.push(_owners[i]);
           isOwner[_owners[i]]=true;
       }
   }


}
