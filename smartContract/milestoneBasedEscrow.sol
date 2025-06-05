

// Build a smart contract that acts as an **escrow for milestone-based payments** between a client and a freelancer.



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MilestoneCon {
    address public client;
    address public freeLancer;
    uint256 public totalPayment;

    enum MilestoneStatus {
        Pending,
        Released
    }

    struct Milestone {
        string description;
        uint256 amount;
        MilestoneStatus status;
    }

    Milestone[] public milestones;

    event MilestoneCreated(string description, uint256 amount);
    event MilestoneReleased(uint256 index, uint256 amount);

    constructor(address _freeLancer, uint256 _totalPayment) payable {
        require(msg.value == _totalPayment, "Must send ether");
        require(_freeLancer != address(0), "Invalid freelancer address");

        client = msg.sender;
        freeLancer = _freeLancer;
        totalPayment = _totalPayment;
    }

    modifier onlyClient() {
        require(msg.sender == client, "Not authorized");
        _;
    }

    // Allow receiving ether (optional/future-proof)
    receive() external payable {}

    // Setup milestones
    function milestoneSet(
        string memory description,
        uint256 amount
    ) public onlyClient {
        require(amount > 0, "Amount must be greater than zero");

        // Calculate total allocated so far
        uint256 totalAllocated = 0;
        for (uint i = 0; i < milestones.length; i++) {
            totalAllocated += milestones[i].amount;
        }

        require(
            totalAllocated + amount <= totalPayment,
            "Total milestones exceed total payment"
        );

        milestones.push(
            Milestone({
                description: description,
                amount: amount,
                status: MilestoneStatus.Pending
            })
        );

        emit MilestoneCreated(description, amount);
    }

    // Release payment for milestone
    function milestoneRelease(uint256 milestoneIndex) public onlyClient {
        require(milestoneIndex < milestones.length, "Invalid milestone index");

        Milestone storage milestone = milestones[milestoneIndex];

        require(
            milestone.status == MilestoneStatus.Pending,
            "Milestone already released"
        );

        milestone.status = MilestoneStatus.Released;

        (bool success, ) = payable(freeLancer).call{value: milestone.amount}("");
        require(success, "Transfer failed");

        emit MilestoneReleased(milestoneIndex, milestone.amount);
    }

    // View remaining unallocated budget
    function getRemainingBudget() public view returns (uint256) {
        uint256 totalAllocated = 0;
        for (uint i = 0; i < milestones.length; i++) {
            totalAllocated += milestones[i].amount;
        }
        return totalPayment - totalAllocated;
    }
}

