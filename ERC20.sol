// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DAO {
    // Token constants
    string public constant NAME = "DAO";
    string public constant SYMBOL = "DAO";
    uint8 public constant DECIMALS = 18;

    // State variables
    uint256 public totalSupply = 10000000 * (10**uint256(DECIMALS));
    address public immutable owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    // Proposal structure with extended fields
    struct Proposal {
        address proposer;
        uint256 endTime;
        bool executed;
        uint256 voteCount;
        uint256 positiveVotes; // Bitmap for positive votes
        ProposalType proposalType;
        uint256 proposedValue;
        address proposedAddress;
    }

    // Proposal type enumeration
    enum ProposalType {
        ChangeFee,
        AllocateFunds
    }

    // Contract parameters
    uint256 public fee; // Hypothetical fee parameter
    address public treasury; // Address for fund allocation

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event ProposalCreated(
        uint256 indexed proposalId,
        ProposalType proposalType,
        uint256 endTime
    );
    event Voted(uint256 indexed proposalId, bool vote);
    event ProposalExecuted(
        uint256 indexed proposalId,
        ProposalType proposalType
    );

    // Constructor sets total supply and owner's balance
    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    // Modifier to restrict function access to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: Not owner");
        _;
    }

    // Transfer tokens to another address
    function transfer(address recipient, uint256 amount) public {
        require(
            balances[msg.sender] >= amount,
            "Transfer amount exceeds balance"
        );
        _transfer(msg.sender, recipient, amount);
    }

    // Internal transfer logic
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(recipient != address(0), "Cannot transfer to the zero address");
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Approve another address to spend tokens
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Internal approval logic
    function _approve(
        address ownerAddr,
        address spender,
        uint256 amount
    ) internal {
        require(spender != address(0), "Cannot approve to the zero address");
        allowed[ownerAddr][spender] = amount;
        emit Approval(ownerAddr, spender, amount);
    }

    // Transfer tokens on behalf of another address
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= balances[from], "Insufficient balance");
        require(amount <= allowed[from][msg.sender], "Allowance exceeded");
        _transfer(from, to, amount);
        _approve(from, msg.sender, allowed[from][msg.sender] - amount);
        return true;
    }

    // Increase the total token supply
    function increaseSupply(uint256 amount) public onlyOwner {
        totalSupply += amount;
        balances[owner] += amount;
        emit Transfer(address(0), owner, amount);
    }

    // Decrease the total token supply
    function decreaseSupply(uint256 amount) public onlyOwner {
        require(balances[owner] >= amount, "Insufficient owner balance");
        totalSupply -= amount;
        balances[owner] -= amount;
        emit Transfer(owner, address(0), amount);
    }

    // Create a governance proposal with type and details
    function createProposal(
        uint256 duration,
        ProposalType proposalType,
        uint256 proposedValue,
        address proposedAddress
    ) public {
        require(balances[msg.sender] > 0, "Only token holders can propose");
        proposals[nextProposalId++] = Proposal({
            proposer: msg.sender,
            endTime: block.timestamp + duration,
            executed: false,
            voteCount: 0,
            positiveVotes: 0,
            proposalType: proposalType,
            proposedValue: proposedValue,
            proposedAddress: proposedAddress
        });
        emit ProposalCreated(
            nextProposalId - 1,
            proposalType,
            block.timestamp + duration
        );
    }

    // Vote on an active proposal
    function voteOnProposal(uint256 proposalId, bool userVote) public {
        require(balances[msg.sender] > 0, "Only token holders can vote");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTime, "Voting ended");
        uint256 voterIndex = uint256(uint160(msg.sender)) % 256;
        uint256 currentVote = (proposal.positiveVotes >> voterIndex) & 1;
        require(currentVote == 0, "Already voted");
        if (userVote) {
            proposal.voteCount++;
            proposal.positiveVotes |= (1 << voterIndex);
        }
        emit Voted(proposalId, userVote);
    }

    // Execute a proposal based on its type after the voting period ends
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting still ongoing");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount > totalSupply / 2, "Majority not reached");

        if (proposal.proposalType == ProposalType.ChangeFee) {
            require(proposal.proposedValue > 0, "Invalid fee value");
            fee = proposal.proposedValue;
        } else if (proposal.proposalType == ProposalType.AllocateFunds) {
            require(proposal.proposedAddress != address(0), "Invalid address");
            require(
                address(this).balance >= proposal.proposedValue,
                "Insufficient balance"
            );
            payable(proposal.proposedAddress).transfer(proposal.proposedValue);
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.proposalType);
    }
}

