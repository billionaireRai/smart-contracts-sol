// SPDX-License-Identifier: MIT
pragma solidity 0.8.25 ;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // for using fungible token standards...
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol"; // used for basic ownership implementations...
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol"; // for signing signature for ERC20 token

contract FirstERC20 is ERC20, ERC20Permit, Ownable {
    constructor(address initialOwner,address mintTo,uint256 tokens) ERC20("firstERC20", "FCT") Ownable(initialOwner) ERC20Permit("firstERC20") {
        require(initialOwner != mintTo,"Cant mint tokens to yourself , ABORTING !!");
          _mint(mintTo,tokens); // minted to my metamask account...
    }
}