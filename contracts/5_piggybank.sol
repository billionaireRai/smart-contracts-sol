// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15 ;

contract SmartPiggyBank {
    // transaction datatype
    struct transaction {
        address acc_address;
        uint amount ;
        uint timeOfTransaction ;
    }

    // account credentials datatype
    struct accBalance {
        uint totalAmountAvailable ;
        uint timeDeposited ;
        mapping(address => transaction) deposits ;
        uint timesWithdrawl ;
        mapping(address => transaction) withdrawls ;
    }

    accBalance public accountBalances ;  // State variable to storing account balances...

    function payEthToContract() public payable {
        transaction memory desposition = transaction(msg.sender,msg.value,block.timestamp) ; // creating deposition instance...
        accountBalances.deposits[msg.sender] = desposition ; // updating the states...
        accountBalances.totalAmountAvailable += msg.value ;
        accountBalances.timeDeposited ++ ;
    }
    
    function withDrawYourEth(address payable _withdrawTo , uint _amount) public  {
        transaction memory withdrawl = transaction(_withdrawTo,_amount,block.timestamp) ; // withdrawl instance...
        accountBalances.withdrawls[msg.sender] = withdrawl ;
        accountBalances.totalAmountAvailable -= _amount ;

        // transfering eths...
        _withdrawTo.transfer(_amount);
        accountBalances.timesWithdrawl ++ ;
    }
}

// Create a contract where:

// Anyone can deposit ETH

// Each user’s balance is stored separately

// User can withdraw only their own deposited ETH

// Add an event Deposited(address user, uint amount)

// Add an event Withdrawn(address user, uint amount)