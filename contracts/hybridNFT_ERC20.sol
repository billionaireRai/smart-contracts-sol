// SPDX-License-Identifier: MIT
pragma solidity 0.8.25 ;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// core concept...
// NFT holders get economic + utility benefits via ERC20 token
// minting NFT gives FT's as well in reward

// contract for logic fungible tokens related logic...
contract ERC20FungibleToken is ERC20, ERC20Permit {
    constructor () ERC20("MYFT","myFtoken") ERC20Permit("mytoken") {}

    uint private constant ERC20SupplyPerNFT = 100 ;

    // function for sending FTs per NFT purchase...
    function dispatchFTsWithNFT(address _sendTo) external {
        _mint(_sendTo,ERC20SupplyPerNFT) ;
    }

    // function for returning balance of a address...
    function BalanceOfAdd(address _address) external returns(uint) {
        return balanceOf(_address) ;
    }

}

// contract logic for NFTs...
contract ERC721NFT is ERC721, Pausable, Ownable, ReentrancyGuard {
    constructor (address contractOwner,address aboveContractAdd) ERC721("MYNFT","myNFtoken") Ownable(contractOwner) {
        _contractOneAdd = aboveContractAdd ;
    }

    enum NFTMintingType { special , normal }  // defining minting types...

    // structure for handling claims overtime...
    struct ERC20Claims {
        uint256 counter ;
        uint256 lastClaimTime ;
    }
    
    // declaring counter variables for tokenids starting from zero...
    using Counters for Counters.Counter ;
    Counters.Counter private  _tokenIds ;

    // defining some events...
    event withdrawAmountFromContract(address _owner,uint256 _amount);
    event NFTminted(address _mintedTo,uint256 _nftId,NFTMintingType _mintType);
    event FTsClaiming(address _claimedBy,uint256 _claimCounter,uint256 _claimedAt);

    // some neccessary variables required...
    bytes32 merkleRoot ;
    address _contractOneAdd ; // for holding above contracts address...
    uint public constant MAX_SUPPLY = 500 ;
    uint public constant specialTokenPrice = 0.1 ether ; 
    uint public tokenPrice = 0.2 ether ; 

    mapping(address => ERC20Claims) private FTclaims ; // storing address claims...

    // modifier for supply and address check...
    modifier supplyAndAddressCheck(address _mintingTo) {
        require(_tokenIds.current() < MAX_SUPPLY, "Max supply reached");
        require(_mintingTo != address(0),"Not a valid address to mint to , ABORTING !!");
        _;
    }

    // modifier for min FT check...
    modifier minFTsForNFTHolder() {
        bytes memory payload = abi.encodeWithSignature("BalanceOfAdd(address)",msg.sender);
        (bool success, bytes memory numBytes) = _contractOneAdd.call(payload);
        require(success, "Call to contract one function failed , ABROTING !!");
        uint256 numOfTokens = abi.decode(numBytes, (uint256));
        require(balanceOf(msg.sender) > 1 && numOfTokens >= 500 ); // required atleast 2 NFTs and 500 FTs...
        _;
    }
    // setting merkle root...
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root ;
    }

    // function to withdraw ethers...
    function withDrawEthers(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance ,"Contract didnt have enough fund , ABORTING !!");
        payable(owner()).transfer(_amount);
        emit withdrawAmountFromContract(owner(),_amount);
    }

    // minting NFTs functionality for whitelisted users...
    function specialNFTMinting(bytes32[] calldata proof, address _mintTo) public payable supplyAndAddressCheck(_mintTo) {
        require(msg.value == specialTokenPrice ,"Exact fund not sent , ABORTING !!");

        // making leaf and checking proof...
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf),"Invalid proof of Whitelist , ABORTING !!");

        _tokenIds.increment() ;
        _safeMint(_mintTo, _tokenIds.current());
        
        emit NFTminted(_mintTo,_tokenIds.current(),NFTMintingType.special);
    }

    // function for highprice minting..
    function normalNFTMinting(address _mintTo) public payable supplyAndAddressCheck(_mintTo) {
        require(msg.value == tokenPrice ,"Exact fund not sent , ABORTING !!");
        require(_tokenIds.current() < MAX_SUPPLY, "Max supply reached");

        _tokenIds.increment() ;
        _safeMint(_mintTo, _tokenIds.current());

        emit NFTminted(_mintTo,_tokenIds.current(),NFTMintingType.normal);

    }

    // function for claiming FTs overtime when modifier condition is reached...
    function overtimeClaimsForFTs() public minFTsForNFTHolder {
        require(block.timestamp - FTclaims[msg.sender].lastClaimTime >= 15 days ,"Days gap must be atleast 15 b/w claims , ABORTING !!") ;
        bytes memory payload = abi.encodeWithSignature("dispatchFTsWithNFT(address)",msg.sender);
        (bool success, ) = _contractOneAdd.call(payload);
        require(success, "Call to contract one function failed , ABROTING !!");

        // first time claiming...
        if (FTclaims[msg.sender].counter == 0)  FTclaims[msg.sender] = ERC20Claims(1, block.timestamp) ;


        FTclaims[msg.sender].counter++ ;
        FTclaims[msg.sender].lastClaimTime = block.timestamp ; // updating to current timestamp...

        emit FTsClaiming(msg.sender,FTclaims[msg.sender].counter,FTclaims[msg.sender].lastClaimTime); 

    }

    // function to toggle pausing...
    function togglePauseState() public onlyOwner {
        if (paused()) _unpause() ;
        else _pause() ;
    }

}