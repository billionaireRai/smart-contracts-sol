// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // used for index based array retrievals...

contract FirstNFTContract is Ownable, ERC721Enumerable {

    constructor(address owner) Ownable(owner) ERC721("chatemoji","CEJ") {}

    function MintNFT(address to, uint256 nftId) public {
        require(totalSupply() < 1000, "Reached total cap of minting, ABORTING!");
        _safeMint(to, nftId);
    }

}