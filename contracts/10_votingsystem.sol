// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChainVotingContract {
    struct Candidate {
        address candidateAddress;
        string name;
        bool hasVoted;
        bool isRegistered;
    }

    address public votingHost;
    uint public totalVotes;
    uint public votingDeadline;

    mapping(address => Candidate) public candidates;

    constructor() {
        votingHost = msg.sender;
        votingDeadline = block.timestamp + 300 ; // deadline after 5 minutes...
    }

    modifier onlyHost() {
        require(msg.sender == votingHost, "UNAUTHORIZED");
        _;
    }

    function registerCandidate(address _candidate, string memory _name) public onlyHost {
        require(!candidates[_candidate].isRegistered, "Already registered");

        candidates[_candidate] = Candidate({
            candidateAddress: _candidate,
            name: _name,
            hasVoted: false,
            isRegistered: true
        });
    }

    function giveYourVote() public {
        Candidate storage senderCandidate = candidates[msg.sender];

        require(senderCandidate.isRegistered, "Not registered");
        require(!senderCandidate.hasVoted, "Already voted");
        require(block.timestamp <= votingDeadline, "Voting period ended");

        senderCandidate.hasVoted = true;
        totalVotes++;
    }
}

// Build a voting contract:

// Owner registers candidates

// Users can vote only once

// Voting ends after a fixed time
