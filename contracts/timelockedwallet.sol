// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract TimeLockedWallet {
    enum TransactionFlow { Inflow, Outflow } // enum for transtion flow direction...

    // type declaration for transaction storage...
    struct TransactionDetails {
        address accountInvolved;
        uint256 amount;
        TransactionFlow flowType;
    }

    // type declaration for amount storage...
    struct AmountType {
        uint256 amount;
        uint256 timeUnlockedAt;
    }

    address payable public ownerOfWallet; // variable for storing owner address...

    constructor() {
        ownerOfWallet = payable(msg.sender);
    }

    // modifier for checking only owner...
    modifier onlyOwner() {
        require(msg.sender == ownerOfWallet, "Not the wallet owner , ABORTING !!");
        _;
    }

    // defining some variables and mapping...
    uint256 public transactionNum;
    mapping(uint256 => TransactionDetails) private transactionRecord;
    mapping(address => AmountType) private amountArr;

    function deposit(uint256 _unlockingAt) public payable {
        require(_unlockingAt > block.timestamp, "Unlock time must be in the future , ABORTING !!"); // checking future time...

        TransactionDetails memory payment = TransactionDetails({
            accountInvolved: msg.sender,
            amount: msg.value,
            flowType: TransactionFlow.Inflow
        });

        if (amountArr[msg.sender].amount == 0) amountArr[msg.sender] = AmountType({ amount: msg.value,timeUnlockedAt: _unlockingAt });

        else amountArr[msg.sender].amount += msg.value;
        

        transactionRecord[transactionNum++] = payment; // storing transaction for deposition...
    }

    function withdrawByOwner(uint256 _withdrawValue) public onlyOwner {
        require(address(this).balance >= _withdrawValue, "Insufficient funds , ABORTING !!");

        TransactionDetails memory withdrawal = TransactionDetails({
            accountInvolved: ownerOfWallet,
            amount: _withdrawValue,
            flowType: TransactionFlow.Outflow
        });

        ownerOfWallet.transfer(_withdrawValue); // sending amount to owner account...
        transactionRecord[transactionNum++] = withdrawal;
    }

    function withdrawFunds(uint256 _value) public {
        AmountType storage userAmount = amountArr[msg.sender];
        require(userAmount.amount <= _value, "Insufficient funds");
        require(block.timestamp <= userAmount.timeUnlockedAt, "Funds are still locked");

        TransactionDetails memory withdrawal = TransactionDetails({
            accountInvolved: msg.sender,
            amount: _value,
            flowType: TransactionFlow.Outflow
        });

        payable(msg.sender).transfer(_value) ; 
        userAmount.amount -= _value;
        transactionRecord[transactionNum++] = withdrawal;
    }

    function getTotalFunds() public view returns (uint256) {
        return address(this).balance;
    }

    function getAccountAmount(address _account) public view returns(uint256, uint256) {
        return (amountArr[_account].amount, amountArr[_account].timeUnlockedAt);
    }
}