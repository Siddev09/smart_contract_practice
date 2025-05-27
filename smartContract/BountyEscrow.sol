// ### 🧠 Challenge 10 — *"BountyEscrow"*

// **Level**: Intermediate
// **Category**: Escrow, Withdraw pattern, Roles
// **Focus**: Access control, payout logic, vault management

// ---

// ### 📋 Problem Statement:

// You're building a `BountyEscrow` contract to manage bounty payments. A `client` funds the contract and assigns a `hunter`. The hunter can only withdraw if the client releases the bounty.

// ---

// ### 🛠️ Functional Requirements:

// ---

// ---

// ---

// ---

// ### 🔐 Constraints:

// * Must prevent reentrancy.
// * Only one withdrawal is allowed.
// * Handle ETH transfers safely.

// ---

// ### 🧠 Design Hints:

// * Track `bountyReleased` and `bountyClaimed` using bool flags.
// * Use `require()` to enforce access control.
// * Avoid double-withdrawal or misuse.

// ---

// Reply with `✅ done` when you've completed it. I'll review and send the next challenge.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BountyEsc {
    address public client;
    address public hunter;
    uint256 public bounty;
    bool public bountyReleased;
    bool public bountyClaimed;

    constructor(address _hunter) payable {
        require(msg.sender != address(0), "Invalid client address");
        require(_hunter != address(0), "Invalid hunter address");
        require(msg.value > 0, "Bounty must be greater than 0");

        client = msg.sender;
        hunter = _hunter;
        bounty = msg.value;
    }

    function release() external {
        require(msg.sender == client, "Only client can release bounty");
        require(!bountyReleased, "Bounty already released");

        bountyReleased = true;
    }

    function withdraw() external {
        require(msg.sender == hunter, "Only hunter can withdraw");
        require(bountyReleased, "Bounty not released");
        require(!bountyClaimed, "Bounty already claimed");

        bountyClaimed = true;

        (bool success, ) = payable(hunter).call{value: bounty}("");
        require(success, "Transfer failed");
    }

    function getStatus()
        external
        view
        returns (bool released, bool claimed)
    {
        return (bountyReleased, bountyClaimed);
    }
}

