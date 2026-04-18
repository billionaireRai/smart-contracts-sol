// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract advanceNFTContract2 is Ownable, ERC721, Pausable, ReentrancyGuard {
    constructor(address contractOwner) Ownable(contractOwner) ERC721("LoyalityCard","LLC") {}
    
    // declaring counter variables...
    using Counters for Counters.Counter ;
    Counters.Counter private _tokenIds ;
    
    // some basic variables...
    uint public constant SUPPLY_CAPACITY = 100;
    uint256 public specialPriceOfNFT = 0.1 ether ;  // for whitelisted accounts...
    uint256 public normalPriceOfNFT = 0.2 ether ; 
    bytes32 public merkleRoot ; // roothash created from pair hashing of whitelisted accounts ...
    mapping(address => bool) private claimForwhiteList ; // claims for whitelisted stored in mapping...

    // setting merkle root...
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root ;
    }

    // functions for updating mint prices...
    function updateSpecialMintPrice(uint256 _newPrice) public onlyOwner {
        specialPriceOfNFT = _newPrice ;
    }

    function updateNormalMintPrice(uint256 _newPrice) public onlyOwner {
        normalPriceOfNFT = _newPrice;
    }

    // function to mint for whitelisted accounts...
    function mintWithProof(bytes32[] calldata proof) external payable whenNotPaused {
        require(_tokenIds.current() < SUPPLY_CAPACITY, "Supply exceeded , ABORTING !!");
        require(msg.value == specialPriceOfNFT,"Exact price value not sent , ABORTING !!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); // creating leaf...
        require(MerkleProof.verify(proof, merkleRoot, leaf),"Invalid proof of Whitelist , ABORTING !!");
        require(!claimForwhiteList[msg.sender], "Already claimed");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        claimForwhiteList[msg.sender] = true;
    }

    // function for normal mint...
    function normalMint() public payable whenNotPaused {
        require(_tokenIds.current() <= SUPPLY_CAPACITY, "Supply exceeded , ABORTING !!");
        require(msg.value == normalPriceOfNFT,"Exact price value not sent , ABORTING !!");

        _tokenIds.increment() ;
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender,newTokenId);
    }

     // function for pause toggle...
    function togglePause() public onlyOwner {
        if (paused()) _unpause() ;
        else _pause() ;
    }

    // function for owner to withdraw balance...
    function withdrawContractBalance() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance) ;
    }

}