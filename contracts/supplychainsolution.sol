// SPDX-License-Identifier: MIT
pragma solidity 0.8.25 ;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // for security of functions handling funds transfer...
import "@openzeppelin/contracts/access/AccessControl.sol";

contract supplyChainContract is AccessControl, Ownable, ReentrancyGuard, Pausable {

    // defining required enums...
    enum availabilityStatus { IN_STOCK , ORDERED , PURCHASED } 
    enum ProductCategory { ELECTRONICS, CLOTHING, FOOD, FURNITURE, BOOKS, TOYS, AUTOMOTIVE, HEALTH, BEAUTY, SPORTS }
    enum SupplyChainStatus { MANUFACTURED, SHIPPED_TO_DISTRIBUTOR, RECEIVED_BY_DISTRIBUTOR, SHIPPED_TO_RETAILER, RECEIVED_BY_RETAILER, 
    SOLD_TO_CUSTOMER }
    enum ControlRoles { ADMIN_ROLE , MANUFACTURER , DISTRIBUTOR , RETAILER , CUSTOMER }

    // declaring counter variable...
    using Counters for Counters.Counter ;
    Counters.Counter private  _productId ;

    // some neccessary structs...
    // individual item tracking by id...
    struct ProductType {
        uint256 unique_id ;
        string name ; 
        uint256 price ;
        ProductCategory category ;
        string description ;
        address current_owner ;
        availabilityStatus availability ;
        SupplyChainStatus current_stage;
        uint256 creation_time ;
    }

    struct transaction {
        address paidBy ;
        uint256 amount ;
        uint256 forProduct ;
        uint256 paidAt ;
    }

    // defining events...
    event ProductCreated(uint256 _productid , address manufacturerAdd , uint256 createdAt);
    event SupplyStageUpdated(SupplyChainStatus _from , SupplyChainStatus _to , uint256 updatedAt);
    event ProductOrdered(uint256 _productid ,address _by , uint256 orderedAt);
    
    // defining mappings for storage...
    mapping(uint256 => ProductType) public totalProducts ;
    mapping(uint256 => transaction) public transactions ;

    bytes32 public constant BRAND_STORE = keccak256("RANDOM_HASH_USED_AS_STORE_ID"); // hash used as store id...

    // generating admin role hash...
    bytes32 public constant ADMIN_ROLE = keccak256(abi.encode(ControlRoles.ADMIN_ROLE));

    // defining some modifiers...
    modifier onlyAdmins() {
        require(hasRole(ADMIN_ROLE,msg.sender), "Unauthorized access Not an ADMIN , ABORTING !!");
        _;
    }

    modifier onlyCertainRole(ControlRoles _roleName) {
        require(hasRole(keccak256(abi.encode(_roleName)), msg.sender), "Only for manufacturers , ABORTING !!");
        _;
    }

    modifier onlyCurrentOwner(uint256 _prodId) {
        ProductType memory product = totalProducts[_prodId] ;
        require(product.current_owner == msg.sender, "Not the current owner to update stage , ABORTING !!"); 
        _;
    }

    constructor(address _owner) Ownable(_owner) {
        _grantRole(ADMIN_ROLE,_owner); // granting admin role to owner itself...
    }

    // function to grant admin roles...
    function GrantAdminRole(address _Address) public onlyOwner {
        require(_Address != address(0), "Invalid address to grant role , ABORTING !!");
        _grantRole(ADMIN_ROLE,_Address);
    }

    // function to grant non-admin roles role...
    function GrantNonAdminRole(address AddToAssign,ControlRoles _role) public onlyAdmins {
        require(!hasRole(ADMIN_ROLE,AddToAssign) && AddToAssign != address(0),"Can't assign admin role , ABORTING !!");
        _grantRole(keccak256(abi.encode(_role)),AddToAssign);
    }

    // function for updating products chain status...
    function UpdateSupplyChainStatus(uint256 _productid , SupplyChainStatus _nextstage) public onlyCurrentOwner(_productid) {
        ProductType storage requiredProduct = totalProducts[_productid] ;
        require(requiredProduct.creation_time != 0, "Product dosent exists , ABORTING !!");
        require(uint256(_nextstage) == uint256(requiredProduct.current_stage) + 1,"Invalid stage transition , ABORTING !!");
        require(requiredProduct.current_stage != _nextstage , "Can't update to same stage , ABORTING !!");


        emit SupplyStageUpdated(requiredProduct.current_stage,_nextstage ,block.timestamp);
        requiredProduct.current_stage = _nextstage ;
    }

    // function for creating a new product...
    function CreateNewProduct(string memory _name,uint256 _price,ProductCategory _category,string memory _desc) public 
    onlyCertainRole(ControlRoles.MANUFACTURER) {
        _productId.increment() ;
        ProductType memory newProduct = 
        ProductType(_productId.current(),_name,_price,_category,_desc,msg.sender,availabilityStatus.IN_STOCK,SupplyChainStatus.MANUFACTURED,block.timestamp);

        totalProducts[_productId.current()] = newProduct ;

        emit ProductCreated(_productId.current(),msg.sender,block.timestamp);
    }
    
    // function to order a product...
    function orderProduct(uint256 _productid) public payable nonReentrant onlyCertainRole(ControlRoles.CUSTOMER) {
        ProductType storage product = totalProducts[_productid] ;
        require(product.creation_time != 0 ,"Item dosent exists , ABORTING !!");
        require(product.availability == availabilityStatus.IN_STOCK, "Item is not is stock , ABORTING !!");
        require(product.current_stage == SupplyChainStatus.MANUFACTURED , "Item is already above in supply chain , ABORTING !!");
        require(product.price == msg.value, "Exact ethers didnt sent , ABORTING !!");

        transactions[_productid] = transaction(msg.sender,product.price,_productid,block.timestamp) ;
        product.availability = availabilityStatus.ORDERED ;
        product.current_owner = msg.sender ; // setting ownership to account interacting...

        emit ProductOrdered(_productid ,msg.sender,block.timestamp);
    }

    // function to withdraw funds...
    function withDrawFunds(uint256 _amountToClaim) public nonReentrant onlyOwner {
        require(_amountToClaim < address(this).balance  , "Contract didnt have enough fund , ABORTING !!");
        payable(owner()).transfer(_amountToClaim) ;
    }
    
    // function to toggle pausing...
    function togglePauseState() public onlyOwner {
        if (paused()) _unpause() ;
        else _pause() ;
    }

    
}