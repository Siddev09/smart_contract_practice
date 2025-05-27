// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TimeLockedAirdrop is ReentrancyGuard {
    address public owner;
    IERC20 public token;
    uint256 public distributionStartTime;

    struct UserData {
        uint256 amount;
        uint256 unlockTime;
        bool hasClaimed;
    }

    mapping(address => UserData) public users;

    event Claimed(address indexed user, uint256 amount);
    event UserRegistered(address indexed user, uint256 amount, uint256 unlockTime);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(IERC20 _token) {
        owner = msg.sender;
        token = _token;
        distributionStartTime = block.timestamp;
    }

    function registerUser(address user, uint256 _amount, uint256 unlockTime) external onlyOwner {
        require(user != address(0), "Invalid address");
        require(_amount > 0, "Zero amount");
        require(unlockTime > block.timestamp, "Unlock time in past");
        require(users[user].amount == 0, "Already registered");

        users[user] = UserData({
            amount: _amount,
            unlockTime: unlockTime,
            hasClaimed: false
        });

        emit UserRegistered(user, _amount, unlockTime);
    }

    function claim() external nonReentrant {
        UserData storage user = users[msg.sender];
        require(user.amount > 0, "Not eligible");
        require(!user.hasClaimed, "Already claimed");
        require(block.timestamp >= user.unlockTime, "Tokens are locked");

        user.hasClaimed = true;
        uint256 amount = user.amount;

        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Claimed(msg.sender, amount);
    }

    function fundAirdrop(uint256 amount) external onlyOwner {
        require(amount > 0, "Zero amount");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function reclaimLeftoverTokens() external onlyOwner {
        require(block.timestamp >= distributionStartTime + 60 days, "Too early");
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }

    // Optional: Add batch registration
    function batchRegisterUsers(address[] calldata addresses, uint256[] calldata amounts, uint256[] calldata unlockTimes) external onlyOwner {
        require(addresses.length == amounts.length && amounts.length == unlockTimes.length, "Array length mismatch");

        for (uint i = 0; i < addresses.length; i++) {
            registerUser(addresses[i], amounts[i], unlockTimes[i]);
        }
    }
}

