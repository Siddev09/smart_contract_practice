// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AllowanceWallet {
    address public owner;

    mapping(address => uint256) private allowances;

    event Deposited(address indexed from, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event AllowanceSet(address indexed user, uint oldAmount, uint newAmount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function setAllowance(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user address");
        uint256 oldAmount = allowances[user];
        uint256 newAmount = oldAmount + amount;

        allowances[user] = newAmount;

        emit AllowanceSet(user, oldAmount, newAmount);
    }

    function reduceAllowance(address user, uint256 amount) internal {
        require(user != address(0), "Invalid user address");
        require(allowances[user] >= amount, "Insufficient allowance");
        allowances[user] -= amount;
    }

    function withdraw(uint256 amount) external {
        require(address(this).balance >= amount, "Insufficient contract balance");

        if (msg.sender == owner) {
            payable(owner).transfer(amount);
        } else {
            require(allowances[msg.sender] >= amount, "Not enough allowance");
            reduceAllowance(msg.sender, amount);
            payable(msg.sender).transfer(amount);
        }

        emit Withdrawn(msg.sender, amount);
    }

    function deposit() external payable {
        require(msg.value > 0, "Send some Ether");
        emit Deposited(msg.sender, msg.value);
    }

    function getAllowance(address user) external view returns (uint256) {
        return allowances[user];
    }

    function getBalance(address user) public view returns (uint256) {
        return user.balance;
    }

    receive() external payable {}
}
