// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // This conntract prevents recursion like situations...
import "@openzeppelin/contracts/access/Ownable.sol";

contract EscrowSmartContract is ReentrancyGuard, Ownable(msg.sender) {

    enum Role { NONE, BUYER, SELLER, ARBITER } // defining roles enums...
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, REFUNDED } // payment status...

    // type for registration information...
    struct Registration {
        Role role;
        bool arbiterApproved;
        uint256 registeredAt;
    }

    // structure for each transaction...
    struct Escrow {
        uint256 id;
        address payable buyer;
        address payable seller;
        uint256 amount;
        EscrowState state;
        bool exists;
    }

    uint256 public escrowCounter; // storing number of transaction...
    uint256 public totalFundsLocked; // total funds in contract...

    mapping(address => Registration) public registrations;
    mapping(uint256 => Escrow) public escrows;

    // events for outer system usage...
    event UserRegistered(address indexed user, Role role);
    event ArbiterApproved(address indexed arbiter);
    event EscrowCreated(uint256 indexed escrowId, address buyer, address seller);
    event Deposited(uint256 indexed escrowId, uint256 amount);
    event Released(uint256 indexed escrowId);
    event Disputed(uint256 indexed escrowId);
    event Resolved(uint256 indexed escrowId, bool releasedToSeller);

    // modifiers for reducing code redundancy...
    modifier onlyRegistered(Role _role) {
        require(registrations[msg.sender].role == _role, "Invalid role");
        _;
    }

    modifier escrowExists(uint256 _id) {
        require(escrows[_id].exists, "Escrow does not exist");
        _;
    }

    // Role registration function...
    function register(Role _role) external {
        require(_role != Role.NONE, "Invalid role");
        require(registrations[msg.sender].role == Role.NONE, "Already registered");

        registrations[msg.sender] = Registration({
            role: _role,
            arbiterApproved: false,
            registeredAt: block.timestamp
        });

        emit UserRegistered(msg.sender, _role);
    }

    // for approving an arbiter by owner (ME)...
    function approveArbiter(address _arbiter) external onlyOwner {
        require(registrations[_arbiter].role == Role.ARBITER, "Not an arbiter");

        registrations[_arbiter].arbiterApproved = true;
        emit ArbiterApproved(_arbiter);
    }

    // ESCROW related logic...
    function createEscrow(address payable _seller) external onlyRegistered(Role.BUYER) returns (uint256) {
        require(registrations[_seller].role == Role.SELLER, "Invalid seller");

        escrowCounter++;

        escrows[escrowCounter] = Escrow({
            id: escrowCounter,
            buyer: payable(msg.sender),
            seller: _seller,
            amount: 0,
            state: EscrowState.AWAITING_PAYMENT,
            exists: true
        });

        emit EscrowCreated(escrowCounter, msg.sender, _seller);
        return escrowCounter;
    }

    // Sending money to created escrow...
    function deposit(uint256 _escrowId) external payable nonReentrant escrowExists(_escrowId) {
        Escrow storage escrow = escrows[_escrowId];

        require(msg.sender == escrow.buyer, "Not buyer");
        require(escrow.state == EscrowState.AWAITING_PAYMENT, "Invalid state");
        require(msg.value > 0, "Must send ETH");

        escrow.amount = msg.value;
        escrow.state = EscrowState.AWAITING_DELIVERY;

        totalFundsLocked += msg.value;

        emit Deposited(_escrowId, msg.value);
    }

    // delivery confirmation from buyer...
    function confirmDelivery(uint256 _escrowId) external nonReentrant escrowExists(_escrowId) {
        Escrow storage escrow = escrows[_escrowId];

        require(msg.sender == escrow.buyer, "Not buyer");
        require(escrow.state == EscrowState.AWAITING_DELIVERY, "Invalid state");

        escrow.state = EscrowState.COMPLETE;
        totalFundsLocked -= escrow.amount;

        uint256 amount = escrow.amount;
        escrow.amount = 0;

        (bool success, ) = escrow.seller.call{value: amount}("");
        require(success, "Transfer failed");

        emit Released(_escrowId);
    }

    // raising dispute if any , by buyer...
    function raiseDispute(uint256 _escrowId) external escrowExists(_escrowId){
        Escrow storage escrow = escrows[_escrowId];

        require(msg.sender == escrow.buyer, "Only buyer can dispute");
        require(escrow.state == EscrowState.AWAITING_DELIVERY, "Cannot dispute");

        escrow.state = EscrowState.DISPUTED;

        emit Disputed(_escrowId);
    }

    // Resolving dispute by arbiter ...
    function resolveDispute(uint256 _escrowId, bool releaseToSeller) external nonReentrant escrowExists(_escrowId) onlyRegistered(Role.ARBITER) {
        require(registrations[msg.sender].arbiterApproved, "Arbiter not approved");

        Escrow storage escrow = escrows[_escrowId];

        require(escrow.state == EscrowState.DISPUTED, "Not disputed");

        totalFundsLocked -= escrow.amount;

        uint256 amount = escrow.amount;
        escrow.amount = 0;

        if (releaseToSeller) {
            escrow.state = EscrowState.COMPLETE;
            (bool success, ) = escrow.seller.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            escrow.state = EscrowState.REFUNDED;
            (bool success, ) = escrow.buyer.call{value: amount}("");
            require(success, "Refund failed");
        }

        emit Resolved(_escrowId, releaseToSeller);
    }

    // view helpers...
    function getEscrow(uint256 _escrowId) external view returns (Escrow memory) {
        return escrows[_escrowId];
    }

    receive() external payable {
        revert("Direct payments not allowed");
    }
}

// Create a contract between:

// Buyer , Seller , Arbiter
// Flow:

// Buyer deposits ETH

// Seller delivers service (off-chain)

// Buyer confirms → Seller gets paid
// OR

// Arbiter can resolve dispute and send funds to either side