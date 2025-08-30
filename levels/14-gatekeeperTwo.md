# 14.GatekeeperTwo
### 原题
这个守门人带来了一些新的挑战, 同样的需要注册为参赛者来完成这一关。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
### 分析
gateOne()这关很好过，直接用中间攻击合约来交互。\
gateTwo()要求里面的 `x == 0`, 这里用了内联汇编`assembly`,只有一行代码 \
`x := extcodesize(caller())`, 我们来看这两个方法的含义 \
`extcodesize` 某个地址的执行代码的大小 \
`caller()` 消息调用者（不包括 delegatecall 调用）\
`extcodesize() == 0`那是不是意味着不能是智能合约直接调用呢？\
不用合约，那怎么去攻击呢，为了满足第一个条件，中间是需要中转合约的。\
有同学会说，那就用EOA账户直接去调用，但是这又不满足第一个关卡条件了。\
这下有点懵了。\
其实在合约即将部署到链上之前，还在执行`constructor`函数阶段，这时候`extcodesize`为0，\
因为合约字节码还没写入到该合约地址上，EVM还在执行`constructor`。\
我们可以利用这点，在`constructor`里发起攻击。\
再来看gateThree()这关，要求我们找到_gateKey，正好符合以下条件: \
`uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max` \
头晕不？各种转换和编码。一个个来分解吧。\
`type(uint64).max` 那64位无符号的数字最大是多少，2 ** 64 - 1; \
`uint64(bytes8(keccak256(abi.encodePacked(msg.sender))))`, \
`msg.sender`是已知的，上面的一串是可以算出来的。\
假设 M 就是计算出来的结果。 \
`^ uint64(_gateKey)` 位运算`异或`, 相同为`0`, 不同为`1`; \
` M ^ uint64(_gateKey) = 2 ** 64 - 1`, \
`2 ** 64 - 1`用二进制表示就是64个1。 \
根据`异或`的运算法则，那就意味着我只要把`M`按位取反就可以得到`uint64(_gateKey)`。\
我们先来试试写个攻击合约。
```solidity
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
```
### 总结
如果我们熟悉智能合约整个发布流程那就可以很快找到攻击方法。所以学习智能合约开发，不仅仅只是编程语言，而是要更多的去了解底层的原理才会有更深的理解。