// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract DecentralizedLotteryContract is Ownable, VRFConsumerBaseV2 {
    uint256 public participationCost = 1 ether;
    uint256 public targetParticipants = 10;
    uint256 public participants;
    uint256 public ids;
    uint256 public prizeMoney;
    uint256 public randomNumber;
    uint256 public fee;
    bytes32 private keyhash ;
    uint256 public lastRequestId;
    uint256 public lastTimestamp;

    struct Joining {
        uint256 id;
        address addr;
        uint256 timestamp;
    }

    mapping(uint256 => Joining) public participantsDetails;

    event participated(address indexed participant, uint256 id);
    event prizeAnnounced(address indexed winner, uint256 prize);

    modifier onlyOneEther() {
        require(msg.value == participationCost, "Incorrect participation cost");
        _;
    }

    modifier checkTargetPartiNotReached() {
        require(participants < targetParticipants, "Target participants reached");
        _;
    }

    constructor(address _vrfCoordinator,address _link,bytes32 _keyHash,uint256 _fee) VRFConsumerBaseV2(_vrfCoordinator, _link) {
        fee = _fee;
        keyhash = _keyHash;
    }

    function participateInLottery() public payable onlyOneEther checkTargetPartiNotReached {
        ids++;
        participants++;
        prizeMoney += participationCost;
        participantsDetails[ids] = Joining(ids, msg.sender, block.timestamp);
        emit participated(msg.sender, ids);
    }

    function getWinnerAccountAndPay() public onlyOwner {
        require(participants >= targetParticipants, "Not enough participants");
        require(block.timestamp > lastTimestamp + 1 days, "Lottery already in progress");

        lastTimestamp = block.timestamp;
        requestRandomNumber();
    }

    function fulfillRandomWords(uint256 , uint256[] memory randomWords) internal override {
        randomNumber = randomWords[0];
        _selectWinner();
    }

    function _selectWinner() private {
        uint256 winnerId = randomNumber % participants;
        address winner = participantsDetails[winnerId + 1].addr;

        (bool success, ) = winner.call{value: prizeMoney}("");
        require(success, "Transfer failed");

        emit prizeAnnounced(winner, prizeMoney);

        // Reset for next lottery
        participants = 0;
        ids = 0;
        prizeMoney = 0;
    }
}
// Decentralized lottery system...

// Build a lottery contract:

// Users enter by paying fixed ETH

// After X players join → pick a winner

// Winner gets all ETH