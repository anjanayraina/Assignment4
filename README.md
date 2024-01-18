# Protocol Overview

The MultiSigWallet contract is designed to establish a multi-signature wallet on the Ethereum blockchain. A multi-signature wallet requires multiple parties, known as owners, to agree on transactions before they can be executed. This type of wallet enhances security by distributing control among several owners rather than relying on a single point of authority.

## Initialization
The contract is deployed with a predefined list of owner addresses and a minimum number of confirmations required to execute a transaction. An admin address is also set, which has the authority to add or remove owners and change the minimum confirmation requirement.

## Owner Management
The admin can add new owners or remove existing ones. Each owner has the `OWNER_ROLE`, which grants them the ability to interact with the wallet's transactional functions.

## Transaction Submission
Owners can submit transactions by specifying the recipient address and the amount of Ether to be transferred. Each submitted transaction is assigned a unique ID and is stored in the contract but not executed immediately.

## Transaction Confirmation
After a transaction is submitted, other owners can confirm it by calling the `confirmTransaction` function with the transaction's ID. Each confirmation is recorded, and the number of confirmations for each transaction is tracked.

## Transaction Execution
Once a transaction has received the required minimum number of confirmations, any owner can execute it by calling the `executeTransaction` function with the transaction's ID. The contract then attempts to transfer the specified amount of Ether to the recipient address. If the transfer is successful, the transaction is marked as executed.

## Transaction Cancellation
Owners who have confirmed a transaction can also cancel their confirmation by calling the `cancelTransaction` function. This decrements the confirmation count for the transaction.

## Batch Execution
The contract provides a function to execute multiple transactions in a single call, provided that each transaction has the required number of confirmations.

## Events
The contract emits events for significant actions, such as when a transaction is submitted, confirmed, executed, or canceled, and when an owner is added or removed. These events facilitate off-chain monitoring and integration.

## Access Control
The contract uses OpenZeppelin's AccessControl for role-based permission management, allowing for flexible control over who can perform certain actions within the contract.

## Reentrancy Protection
The contract includes OpenZeppelin's ReentrancyGuard to prevent reentrancy attacks during the execution of transactions.

## Funding
The contract can receive Ether directly to its address, which can then be managed through the multi-signature process.


# How to run
1.  **Install Foundry**

First, run the command below to get Foundryup, the Foundry toolchain installer:

``` bash
curl -L https://foundry.paradigm.xyz | bash
```

Then, in a new terminal session or after reloading your PATH, run it to get the latest forge and cast binaries:

``` console
foundryup
```

2. **Clone This Repo and install dependencies**
``` 
git clone https://github.com/anjanayraina/Assigment1
cd Assigment1
forge install

```

3. **Run the Tests**



``` 
forge test
```
# Design Choices in the MultiSigWallet Contract

The MultiSigWallet contract incorporates several design choices that reflect its intended use as a secure, collective fund management tool. Here are some of the key design choices made in the protocol:

## Role-Based Access Control
The contract uses OpenZeppelin's AccessControl to manage roles and permissions. This allows for a flexible and secure way to handle permissions for different actions within the contract, such as submitting and confirming transactions, as well as administrative functions like adding or removing owners.

## Minimum Confirmation Requirement
The protocol requires a minimum number of confirmations from different owners before a transaction can be executed. This threshold is set at deployment and can be changed by the admin, ensuring that no single owner can unilaterally move funds.

## Transaction Queue
Transactions are not executed immediately upon submission. Instead, they are queued and identified by a unique hash, allowing owners to review and confirm each transaction before execution.

## Confirmation Tracking
The contract tracks which owners have confirmed each transaction, preventing duplicate confirmations and allowing owners to cancel their confirmations if needed.

## Batch Execution
The protocol includes a function to execute multiple confirmed transactions in one call, improving efficiency and saving on gas costs when processing several transactions.

## Event Logging
The contract emits events for critical actions, providing transparency and enabling off-chain applications to react to changes within the wallet.

## Reentrancy Protection
The ReentrancyGuard from OpenZeppelin is used to prevent reentrancy attacks, a common security vulnerability in smart contracts that handle external calls transferring Ether or tokens.

## Ether Management
The contract is designed to handle Ether transactions. It includes a receive function to accept direct Ether transfers into the contract's balance.

## Custom Errors
The contract uses custom errors for reverting transactions instead of traditional require statements with error messages. This can save gas and provide clearer reasons for transaction failures.

# Security Considerations 

The MultiSigWallet contract includes several security considerations to ensure the safe management of funds and robust operation of the wallet. Here are some of the key security considerations made in the contract:

## Role-Based Access Control
The contract uses OpenZeppelin's AccessControl to manage roles and permissions, preventing unauthorized access to critical functions. Only addresses with the `OWNER_ROLE` can submit, confirm, or execute transactions, and only the admin can add or remove owners.

## Minimum Confirmation Requirement
A minimum number of confirmations from different owners is required to execute a transaction, mitigating the risk of a single owner acting maliciously or an external attacker compromising a single owner's account.

## Reentrancy Protection
The contract inherits from OpenZeppelin's ReentrancyGuard, preventing reentrancy attacks—a common vulnerability in contracts that interact with external addresses.

## Immutable Role Definitions
The `OWNER_ROLE` is defined as a constant, preventing it from being modified after deployment, and ensuring that the security model cannot be altered.

## Custom Errors
The contract uses custom errors instead of revert strings, saving gas and providing clearer reasons for transaction failures. This helps in identifying issues more efficiently during interactions with the contract.

## Event Logging
The contract emits events for significant actions, such as transaction submission, confirmation, execution, and owner management. This allows for better monitoring and auditing of contract activity.

## Confirmation Tracking
The contract maintains a mapping of confirmations for each transaction, ensuring that confirmations are tracked individually and cannot be duplicated.

## Checks-Effects-Interactions Pattern
The contract attempts to follow the checks-effects-interactions pattern, where state changes are made before external calls to prevent reentrancy issues.

## Secure Ether Handling
The contract includes a receive function to safely accept Ether transfers directly to the contract's address.

## Transaction Execution Authorization
The contract is designed to check for the required number of confirmations before allowing a transaction to be executed

## No External Calls in Constructors
The constructor does not make external calls, which is a good practice to avoid attacks during contract creation.


