// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MiniDAO {
    // =========================
    // ======= STORAGE =========
    // =========================

    IERC20 public governanceToken;
    uint public constant MIN_TOKENS_TO_PROPOSE = 100 * 1e18;
    uint public constant MIN_TOKENS_TO_VOTE = 100 * 1e18;
    uint public constant QUORUM_PERCENTAGE = 20;

    struct Proposal {
        string description;
        uint voteStart;
        uint voteEnd;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }

    Proposal[] public proposals;

    mapping(uint => mapping(address => bool)) public hasVoted;

    // =========================
    // ======= EVENTS ==========
    // =========================

    event ProposalCreated(uint indexed id, string description, uint voteStart, uint voteEnd);
    event Voted(uint indexed proposalId, address indexed voter, bool support, uint weight);
    event ProposalExecuted(uint indexed proposalId);

    // =========================
    // ======= INIT ============
    // =========================

    constructor(address _tokenAddress) {
        governanceToken = IERC20(_tokenAddress);
    }

    // =========================
    // ======= MODIFIERS =======
    // =========================

    modifier onlyTokenHolders(uint minBalance) {
        require(governanceToken.balanceOf(msg.sender) >= minBalance, "Not enough tokens");
        _;
    }

    // =========================
    // ======= FUNCTIONS =======
    // =========================

    /// @notice Create a new proposal
    function createProposal(string calldata description, uint duration)
        external
        onlyTokenHolders(MIN_TOKENS_TO_PROPOSE)
    {
        require(duration > 0, "Duration must be > 0");

        uint start = block.timestamp;
        uint end = block.timestamp + duration;

        proposals.push(Proposal({
            description: description,
            voteStart: start,
            voteEnd: end,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        }));

        emit ProposalCreated(proposals.length - 1, description, start, end);
    }

    /// @notice Vote on a proposal
    function vote(uint proposalId, bool support)
        external
        onlyTokenHolders(MIN_TOKENS_TO_VOTE)
    {
        Proposal storage prop = _getProposal(proposalId);

        require(block.timestamp >= prop.voteStart, "Voting hasn't started");
        require(block.timestamp <= prop.voteEnd, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        if (support) {
            prop.yesVotes += weight;
        } else {
            prop.noVotes += weight;
        }

        hasVoted[proposalId][msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, weight);
    }

    /// @notice Execute a proposal if passed
    function executeProposal(uint proposalId) external {
        Proposal storage prop = _getProposal(proposalId);

        require(block.timestamp > prop.voteEnd, "Voting still active");
        require(!prop.executed, "Already executed");

        uint totalVotes = prop.yesVotes + prop.noVotes;
        uint totalSupply = governanceToken.totalSupply();
        uint quorum = (totalSupply * QUORUM_PERCENTAGE) / 100;

        require(totalVotes >= quorum, "Quorum not reached");
        require(prop.yesVotes > prop.noVotes, "Proposal not approved");

        prop.executed = true;

        emit ProposalExecuted(proposalId);
    }

    // =========================
    // ======= HELPERS =========
    // =========================

    function _getProposal(uint id) internal view returns (Proposal storage) {
        require(id < proposals.length, "Invalid proposal ID");
        return proposals[id];
    }

    /// @notice Get total number of proposals
    function getProposalCount() external view returns (uint) {
        return proposals.length;
    }

    /// @notice Get proposal details
    function getProposal(uint id)
        external
        view
        returns (
            string memory description,
            uint voteStart,
            uint voteEnd,
            uint yesVotes,
            uint noVotes,
            bool executed
        )
    {
        Proposal memory p = proposals[id];
        return (p.description, p.voteStart, p.voteEnd, p.yesVotes, p.noVotes, p.executed);
    }
}

