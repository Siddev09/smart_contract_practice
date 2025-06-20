// Here's your next **smart contract challenge**, designed for **intermediate-level practice**. This one tests your **understanding of payments, withdrawal patterns, and ownership control** — often asked in interviews.

// ---

// ### 📦 Smart Contract: **Refundable Crowdsale**

// #### 📘 Situation:

// You are tasked to build a **Crowdsale** smart contract that accepts ETH from participants for a project. If the **goal** is reached by the **deadline**, the owner can withdraw the funds. Otherwise, contributors can **claim refunds**.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RefundableCrowd {
    address public owner;
    uint public deadline;
    uint public fundingGoal;
    mapping(address => uint) public contributors;

    event Contributed(address indexed user, uint256 amount);
    event FundWithdrawn(uint amount);
    event RefundIssued(address indexed user, uint256 amount);

    constructor(uint _goal, uint256 _durationInSec) {
        owner = msg.sender;
        fundingGoal = _goal;
        deadline = block.timestamp + _durationInSec;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function contribute() external payable {
        require(msg.sender != address(0), "Invalid address");
        require(msg.sender != owner, "Owner not allowed to contribute");
        require(block.timestamp <= deadline, "Deadline passed");
        require(msg.value > 0, "Contribution must be > 0");

        contributors[msg.sender] += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    function withdraw(uint amount) external onlyOwner {
        require(block.timestamp > deadline, "Crowdfunding still active");
        require(address(this).balance >= fundingGoal, "Goal not reached");
        require(amount <= address(this).balance, "Insufficient funds");

        (bool sent, ) = payable(owner).call{value: amount}("");
        require(sent, "Transfer failed");

        emit FundWithdrawn(amount);
    }

    function claimRefund() external {
        require(block.timestamp > deadline, "Crowdfunding still active");
        require(address(this).balance < fundingGoal, "Goal was met");
        uint256 contributed = contributors[msg.sender];
        require(contributed > 0, "No contribution to refund");

        contributors[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: contributed}("");
        require(sent, "Refund failed");

        emit RefundIssued(msg.sender, contributed);
    }
}
