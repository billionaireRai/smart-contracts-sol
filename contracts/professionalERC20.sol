// SPDX-License-Identifier: MIT
pragma solidity 0.8.25 ;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProfessionalERC20 is ERC20, Ownable, ERC20Permit {
    constructor(address firstOwner) ERC20("profERC20","PEC") Ownable(firstOwner) ERC20Permit("profERC20") {}

    // function by which anyone can mint tokens...
    function mintTokens(address to,uint256 tokens) public onlyOwner {
        _mint(to,tokens);
    }

    // function to burn own tokens...
    function burnOwnTokens(uint256 tokens) public {
        require(balanceOf(_msgSender()) >= tokens , "Not Enough fund to burn ,, ABORTING !!");
        _burn(_msgSender(),tokens);
    }
}