// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15 ;

contract MyContract {
    // defining a string variable...
    // string public ourString = "Hello-world";

    // function for updating that variable...
    // function updateOurString(string memory _updatedString) public {
    //     ourString = _updatedString ;
    // }

    // bool public myValue ; // default value false.

    // updation function...
    // function changeMyValue(bool _newValue) public {
    //     myValue = _newValue ;
    // }

    // storing unsigned integer...
    // uint public myInteger = 1712 ;

    // updating function.
    // function updateMyInteger(uint _num) public {
    //     myInteger = _num ;
    // }

    // wokring with uint265
    // uint256 public number ;
    // function decrementUnchecked() public {
    //     unchecked {
    //         number--  ;
    //     }
    // } 

    // function checkedDecrement() public {
    //         number--  ;
    // }

 
    // function setMyString(string memory _myString) public {
    //     ourString = _myString;
    // }
 
    // function compareTwoStrings(string memory _myString) public view returns(bool) {
    //     return keccak256(abi.encodePacked(ourString)) == keccak256(abi.encodePacked(_myString));
    // }

    // playing with etherium address..
    // address public someETHAaddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 ;

    // function for getting the balance...
    // function getETHaccountbalance() public view  returns(uint) {
    //     return someETHAaddress.balance ;
    // }

    // my first mini project..
    string public secretString ;
    uint8 public updateCounter ;

    address public ownerAddress ; // cant be changed...

    constructor() {
        address add = msg.sender ;
        ownerAddress = add ;
    }

    function handlingStringUpdation(string memory _someString) public {
        if (ownerAddress == msg.sender) {
            secretString = _someString ;
            updateCounter++ ;
        }
    }


}