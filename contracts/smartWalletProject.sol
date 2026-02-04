// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract smartWalletContract {

    // struct for record type...
    struct accBalanceRecord {
        address ofAddress ;
        uint amountStored ;
        uint latestAddAt ;
        uint registeredAt ;
    }

    uint accountAllowanceToSpend = 100 ;
    address payable ownerAccAdd ; // variable for storing owner account address...
    constructor() {
        ownerAccAdd = payable(msg.sender) ;
    }

    mapping( address => accBalanceRecord ) public Records ; // mapping storing all records..

    // function handling registration in wallet...
    function registerInWallet(address _addressToRegister) public {
        require( Records[_addressToRegister].ofAddress != _addressToRegister , "Address already registered , ABORTING!!" );
        accBalanceRecord memory newRecord = accBalanceRecord( _addressToRegister , 0 , 0 , block.timestamp );
        Records[_addressToRegister] = newRecord ;
    }

    // function for getting total balance of wallet...
    function getTotalBalanceOfWallet() public view returns(uint) {
        return address(this).balance ;
    }
    
    // fallback function reciving funds...
    fallback() external payable {
        require( msg.sender != ownerAccAdd , "Owner Can't use himself , ABORTING !!");
        require( Records[msg.sender].registeredAt != 0 , "Account need to be registered , ABORTING !!");
        Records[msg.sender].amountStored += msg.value ;
        Records[msg.sender].latestAddAt = block.timestamp ;

    }

    // function handling spending of money...
    function spendSomeMoney(address payable _addressOnSend,uint _amount) public {
        if (msg.sender == ownerAccAdd) {
            require( _amount <= address(this).balance , "Not Enough fund to withdraw , ABORTING !!");
            _addressOnSend.transfer(_amount);
        } else {
            require( Records[msg.sender].amountStored >= _amount , "Not Enough fund to withdraw , ABORTING !!");
            require( _amount <= accountAllowanceToSpend , "Allowance money limit exceeded ( 100 wei ), ABORTING !!");
            require( Records[msg.sender].registeredAt != 0 , "Account need to be registered , ABORTING !!");
            _addressOnSend.transfer(_amount);

        }
    }

    // function setting new owner...
    function setNewOwner(address payable _accountAdd) public {
        require( msg.sender == ownerAccAdd , "Only owner can set Owner , ABORTING !!");
        ownerAccAdd = _accountAdd ;
    }

    receive() external payable {
        revert("Use fallback() for deposits");
    }
}