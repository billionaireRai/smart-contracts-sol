// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract JointSmartWallet {
    struct Transaction {
        address addr;
        uint256 amount;
        uint256 timestamp;
    }

    // storing owner address...
    address payable public ownerAdd1;
    address payable public ownerAdd2;

    // storing owner consents...
    bool public consentOf1;
    bool public consentOf2;

    mapping(address => Transaction) public transactions ; // storing all the transaction...

    constructor(address payable _owner1, address payable _owner2) {
        ownerAdd1 = _owner1;
        ownerAdd2 = _owner2;
    }

    function deposit() public payable {
        transactions[msg.sender] = Transaction(msg.sender, msg.value, block.timestamp);
    }

    function toggleConsent() public {
        if (msg.sender == ownerAdd1) {
            consentOf1 = !consentOf1;
        } else if (msg.sender == ownerAdd2) {
            consentOf2 = !consentOf2;
        }
    }

    function withdrawEqually(uint256 _amount) public {
        require((msg.sender == ownerAdd1 || msg.sender == ownerAdd2) && consentOf1 && consentOf2,"Permission denied by any of owner !!");
        require(address(this).balance > _amount, "Insufficient balance");

        // Update transaction record...
        transactions[msg.sender] = Transaction(msg.sender, _amount, block.timestamp);

        // Transfering amount to interacting account...
        payable(msg.sender).transfer(_amount);

        // Reset consents after withdrawal..
        consentOf1 = false;
        consentOf2 = false;
    }
}

// Create a contract that:

// Has 2 fixed owners

// ETH can be deposited by anyone

// Withdrawal requires both owners to approve

// Once both approve → funds can be withdrawn

// withdrawl ammount get divided equally b/w the owners