// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol"; // used for freezing all token transfers some emergency...
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract advanceNftContract is Ownable, ERC721, ERC721Pausable, ERC721Enumerable, ReentrancyGuard {
    constructor(address ownerAdd) Ownable(ownerAdd) ERC721("ChatEmojiIcon", "CEI") {}

    // some required variables to use...
    uint256 public constant MAX_SUPPLY = 500 ;
    uint256 public nftPrice = 0.1 ether ;
    uint256 private tokenIds ;

    // event involved...
    event NFTMinted(address indexed account , uint256 quantity);

    // funtion to mint NFT anyone...
   function mintNFT(address to, uint256 quantity) public payable whenNotPaused {
      require(quantity > 0, "Impossible to send tokens less than 0, ABORTING!!");
      require(tokenIds + quantity <= MAX_SUPPLY, "Exceeding max NFT supply, ABORTING!!");
      require(msg.value == quantity * nftPrice, "Exact fund not sent, ABORTING!!");

      uint256 startId = tokenIds + 1;
      for (uint256 i = startId ; i <= quantity ; i++) _safeMint(to,i) ; 
      
      tokenIds += quantity;

      emit NFTMinted(to, quantity);
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

    function setMintPrice(uint256 _price) external onlyOwner {
        nftPrice = _price ;
    }

    // some overriding functions required...
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable, ERC721Pausable) returns(address){
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns(bool){
        return super.supportsInterface(interfaceId);
    }

    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

}