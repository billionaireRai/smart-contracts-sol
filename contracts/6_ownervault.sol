// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15 ;

contract mySecuredVault {

    address payable ownerAccAddress ;
    constructor () {
        ownerAccAddress = payable(msg.sender) ; // setting my account as owner...
    }
    
    mapping(address => uint) public balances ; // storing balances of all address...
    uint public depositeNums ;
    function payEthersToContract() public payable {
        balances[msg.sender] += msg.value ;
        depositeNums ++ ;
    }
    
    function totalDepositedBalance() public view returns (uint256) {
        return address(this).balance ;  
    }

    function withDrawEthers(uint _amount) public {
        require(msg.sender == ownerAccAddress, "Not allowed to withdraw ABORTING!!");
        uint totalBalance = totalDepositedBalance();
        require(_amount <= totalBalance, "Insufficient balance");
        payable(ownerAccAddress).transfer(_amount);  
}

}

// Build a vault contract where:

// Contract has an owner (set at deployment)

// Anyone can send ETH to the contract

// Only the owner can withdraw

// Add a function to check total contract balance

// Prevent non-owners from withdrawing (use require)