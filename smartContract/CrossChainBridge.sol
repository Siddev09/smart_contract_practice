// ### 📝 Problem Statement

// You're tasked with building the **on-chain contract** for a **one-way token bridge**. Assume there's an off-chain relayer that reads and submits proofs.


// ---
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrossChainBridge {
    IERC20 public token;
    address public owner;
    address public relayer;

    mapping(address => uint256) public nonces;
    mapping(address => mapping(uint256 => bool)) public claimed;

    event TokenDeposited(address indexed user, uint256 amount, uint256 nonce);
    event TokenClaimed(address indexed user, uint256 amount, uint256 nonce);

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice Set the trusted relayer address
    function setRelayer(address _relayer) external onlyOwner {
        require(_relayer != address(0), "Zero relayer");
        relayer = _relayer;
    }

    /// @notice Deposit tokens to be bridged
    function deposit(uint256 amount) external {
        require(amount > 0, "Zero amount");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 userNonce = nonces[msg.sender];
        emit TokenDeposited(msg.sender, amount, userNonce);
        nonces[msg.sender]++;
    }

    /// @notice Claim bridged tokens from other chain
    function claim(address user, uint256 amount, uint256 nonce, bytes calldata signature) external {
        require(!claimed[user][nonce], "Already claimed");
        require(relayer != address(0), "Relayer not set");

        bytes32 message = keccak256(abi.encodePacked(user, amount, nonce));
        bytes32 ethSignedMessage = toEthSignedMessageHash(message);
        address signer = recover(ethSignedMessage, signature);

        require(signer == relayer, "Invalid signature");

        claimed[user][nonce] = true;
        require(token.transfer(user, amount), "Transfer failed");

        emit TokenClaimed(user, amount, nonce);
    }

    /// @notice Recover address from signed message
    function recover(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_hash, v, r, s);
    }

    /// @notice Add prefix to message hash to mimic behavior of eth_sign
    function toEthSignedMessageHash(bytes32 _hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }
}

