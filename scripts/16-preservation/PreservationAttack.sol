// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreservationAttack {
    address public v1;
    address public v2;
    uint256 public storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}