// SPDX-License-Identifier: MIT
pragma solidity 0.8.25 ;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AdvanceEscrowSystem is Ownable , AccessControl , Pausable , ReentrancyGuard {

    // defining some basic enums...
    enum SystemRoles { BUYER , SELLER , ARBITRATOR }
    enum disputeResolveOptions { PAY_TO_SELLER , REFUND_TO_BUYER }
    enum availabilityStatus { IN_STOCK , ORDERED , PURCHASED } 
    enum OrderStage { CREATED , ACCEPTED , SHIPPED , DELIVERED } 

    using Counters for Counters.Counter ;
    Counters.Counter private  _orderId ;

    // defining structures needed...
    struct Order {
      uint256 orderid ;
      address buyer ;
      address seller ;
      uint256 amount ;
      OrderStage stage ; 
      availabilityStatus availability ;
      uint256 createdAt ;
      bool disputed ;
    }

    struct Transaction {
        address paidBy ;
        uint256 amount ;
        uint256 forProduct ;
        uint256 paidAt ;
    }

    struct BuyerSellerAgreed {
        bool buyerAgreed ;
        bool sellerAgreed ;
    }
    
    disputeResolveOptions public disputeSolution = disputeResolveOptions.PAY_TO_SELLER ; // storing a string on aggreement...
    // generating unique hashes for each roles...
    bytes32 private constant ARBITRATOR_ROLE = keccak256("ARBITRATOR_ROLE") ; 
    bytes32 private constant BUYER_ROLE = keccak256("BUYER_ROLE") ; 
    bytes32 private constant SELLER_ROLE = keccak256("SELLER_ROLE") ; 

    constructor(address _ownerAddress) Ownable(_ownerAddress) {
        _grantRole(ARBITRATOR_ROLE,_ownerAddress) ;
    }

    // mappings for storage...
    mapping(uint256 => Order) public OrderHistory ;
    mapping(address => mapping(uint256 => Transaction)) public transactionHistory ;
    mapping(uint256 => mapping(disputeResolveOptions => BuyerSellerAgreed)) public agreedByBoth ;

    // logical checks segrigation by modifiers...
    modifier onlyPaticularRole(bytes32 _RoleSpecificHash) {
        require(hasRole(_RoleSpecificHash,_msgSender()), "Interactor is Unauthorized , ABORTING !!");
        _;
    }

    modifier notPaticularRole(bytes32 _rolehash) {
        require(!hasRole(_rolehash,_msgSender()), "Interactor has paticular role , ABORTING !!");
        _;
    }

    modifier onlyDisputedOrders(uint256 _orderid) {
        Order storage requiredOrder = OrderHistory[_orderid] ;
        require(requiredOrder.disputed == true , "Order isnt disputed , ABORTING !!");
        _;
    }

    // function to grant role => address...
    function GrantRole(address _Address,SystemRoles _rolename) public onlyOwner {
        require(_Address != address(0), "Invalid address to grant role , ABORTING !!");
        _grantRole(keccak256(abi.encode(_rolename)),_Address);
    }

    function changeResolveOption() public onlyPaticularRole(ARBITRATOR_ROLE) {
        if (disputeSolution == disputeResolveOptions.PAY_TO_SELLER)  disputeSolution = disputeResolveOptions.REFUND_TO_BUYER ;
        else disputeSolution = disputeResolveOptions.REFUND_TO_BUYER ;
        
    }

    // function to raise concern...
    function RaiseConcern(uint256 _orderID) public notPaticularRole(ARBITRATOR_ROLE) {
        Order storage requiredOrder = OrderHistory[_orderID] ;
        require(requiredOrder.createdAt != 0 , "Order doesnt exists , ABORTING !!");
        require(requiredOrder.availability == availabilityStatus.ORDERED, "Order must be in supply chain , ABORITNG !!");

        // setting disputed as true...
        requiredOrder.disputed = true ;
    }

    // function to agree on fund release in dispute...
    function AgreeToDisputeSolution(uint256 _orderid) public notPaticularRole(ARBITRATOR_ROLE) {
        Order storage requiredOrder = OrderHistory[_orderid] ;
        require(requiredOrder.createdAt != 0 , "Order doesnt exists , ABORTING !!");

        BuyerSellerAgreed storage agreementArr = agreedByBoth[_orderid][disputeSolution] ;

        if (_msgSender() == requiredOrder.buyer) agreementArr.buyerAgreed = true ;
        if (_msgSender() == requiredOrder.seller) agreementArr.buyerAgreed = true ;
    }

    // funtion for releasing fund incase of dispute...
    function ReleaseFundInDispute(uint256 _orderid) public nonReentrant onlyDisputedOrders(_orderid) onlyPaticularRole(ARBITRATOR_ROLE) {
        Order storage requiredOrder = OrderHistory[_orderid] ;
        require(requiredOrder.createdAt != 0 , "Order doesnt exists , ABORTING !!");

        BuyerSellerAgreed storage agreementArr = agreedByBoth[_orderid][disputeSolution] ;

        if (agreementArr.buyerAgreed == true && agreementArr.sellerAgreed == true && disputeSolution == disputeResolveOptions.PAY_TO_SELLER) {

        }
        if (agreementArr.buyerAgreed == true && agreementArr.sellerAgreed == true && disputeSolution == disputeResolveOptions.REFUND_TO_BUYER) {

        }

    }
    
    // function to toggle pausing...
    function togglePauseState() public onlyOwner {
        if (paused()) _unpause() ;
        else _pause() ;
    }
    
}