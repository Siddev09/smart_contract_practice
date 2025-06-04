

// Build a secure ETH vault contract where users can deposit and withdraw ETH,
// with added access control and safety features. This will get you comfortable with fallback functions, `msg.sender`, access modifiers, balance tracking, and security patterns.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ETHVault {
    address public owner;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public withdrawnToday;

    uint256 public maxDailyLimitPercent = 60; // e.g., 60% of user's balance

    bool public pauseDeposit;
    bool public pauseWithdraw;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 time);
    event Paused(string action, bool state);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPausedDeposit() {
        require(!pauseDeposit, "Deposits paused");
        _;
    }

    modifier notPausedWithdraw() {
        require(!pauseWithdraw, "Withdrawals paused");
        _;
    }

    function deposit() external payable notPausedDeposit {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notPausedWithdraw {
        require(msg.sender != address(0), "Invalid address");
        require(amount > 0, "Amount must be > 0");
        require(amount <= balances[msg.sender], "Insufficient balance");

        // Reset daily withdrawal tracker if 24h passed
        if (block.timestamp > lastWithdrawTime[msg.sender] + 1 days) {
            withdrawnToday[msg.sender] = 0;
            lastWithdrawTime[msg.sender] = block.timestamp;
        }

        uint256 maxAllowed = (balances[msg.sender] * maxDailyLimitPercent) / 100;
        require(
            withdrawnToday[msg.sender] + amount <= maxAllowed,
            "Exceeds daily withdrawal limit"
        );

        // Update before sending (Checks-Effects-Interactions)
        balances[msg.sender] -= amount;
        withdrawnToday[msg.sender] += amount;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Transfer failed");

        emit Withdrawn(msg.sender, amount, block.timestamp);
    }

    // Pause/unpause controls
    function setPauseDeposit(bool _pause) external onlyOwner {
        pauseDeposit = _pause;
        emit Paused("deposit", _pause);
    }

    function setPauseWithdraw(bool _pause) external onlyOwner {
        pauseWithdraw = _pause;
        emit Paused("withdraw", _pause);
    }

    // Update the withdrawal percentage limit (owner only)
    function setMaxDailyLimitPercent(uint256 percent) external onlyOwner {
        require(percent > 0 && percent <= 100, "Invalid percent");
        maxDailyLimitPercent = percent;
    }

    // Fallback ETH deposit
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
