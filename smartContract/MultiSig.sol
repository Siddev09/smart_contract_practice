// ## 🔐 MultiSigWallet (Lite)
// Build a minimal multi-signature wallet that allows multiple owners to collectively approve and execute transactions.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract multisig {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    address owner;
    uint256 confirmation;
    address[] public owners;

    Transaction[] public transactions;

    mapping(uint => mapping(address => bool)) public isConfirmed;

    constructor(uint256 _confirmation) {
        require(msg.sender != address(0), "invalid address");
        owner = msg.sender;
        confirmation = _confirmation;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function submitTransaction(
        address to,
        uint value,
        bytes calldata data
    ) public {
        require(to != address(0), "Invalid address"); // Ensure the address is valid

        // Create a new transaction
        Transaction memory newTransaction = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            numConfirmations: 0
        });

        // Add the transaction to the list
        transactions.push(newTransaction);
    }

    function confirmTransaction(uint txId) public onlyOwner {
        require(transactions[txId].executed != true, "already executed");
        require(
            !isConfirmed[txId][msg.sender],
            "Transaction already confirmed by this owner"
        ); // Prevent duplicate confirmations

        transactions[txId].numConfirmations++;
        isConfirmed[txId][msg.sender] = true; // Mark this owner as having confirmed the transaction
    }

    function executeTx(uint txId) public onlyOwner {
        require(
            transactions[txId].numConfirmations >= confirmation,
            "not confirmed by owners"
        ); // Check if the transaction has enough confirmations
        require(!transactions[txId].executed, "transaction already executed"); // Ensure the transaction hasn't been executed

       
        transactions[txId].executed = true; // Mark the transaction as executed
    }
}
