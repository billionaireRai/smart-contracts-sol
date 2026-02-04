// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract smartCrowdFundingContract {
    struct deposition {
        address from ;
        uint amount ;
        uint timestamp ;
    }
    struct FundingStruct {
        uint fundingAmount ;
        uint availableAmount ;
        uint deadline ;
    }

    address payable ownerAdd ; // for storing owner address...
    FundingStruct public fundingDetails ;
    constructor() {
        ownerAdd = payable(msg.sender) ;
        fundingDetails = FundingStruct( 100 , 0 , block.timestamp + 5 minutes ); // making a funding instance...
    }
    mapping (address => deposition) public Deposits ;
    uint public numOfDeposits ;
    function donateFundToContract() public payable {
        require(
            block.timestamp <= fundingDetails.deadline && fundingDetails.availableAmount < fundingDetails.fundingAmount , 
            "Can't Donate, deadline exceeded ABORTING!!"
        );
        deposition memory deposite = deposition(msg.sender,msg.value,block.timestamp) ; // making a new depostion instance...
        Deposits[msg.sender] = deposite ;
        numOfDeposits ++ ;
        fundingDetails.availableAmount += msg.value ;
    }

    function withDrawEthFromContract() public {
        if (block.timestamp <= fundingDetails.deadline)  {
            require(fundingDetails.availableAmount >= fundingDetails.fundingAmount);
            ownerAdd.transfer(fundingDetails.availableAmount) ; // withdrawing accomodated amount...

            fundingDetails.availableAmount = 0 ; // reseting the available amount...
            fundingDetails.fundingAmount = 0 ; // reseting the funding amount...
        } else {
            deposition memory depositeMade = Deposits[msg.sender] ;
            require(depositeMade.from == msg.sender, "UNAUTHORIZED for withdrawl ABORTING !!");
            payable(depositeMade.from).transfer(depositeMade.amount); // sending back to depositor...

            delete  Deposits[msg.sender] ; // deleting the deposite...
            numOfDeposits -- ;
        }
    }
}

// Create a crowdfunding contract where:

// Owner sets:

// Funding goal
// Deadline (timestamp)

// People can fund the project

// If goal is reached before deadline → owner can withdraw

// If goal NOT reached → users can refund themselves