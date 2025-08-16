# 12. Privacy
### 原题
这个合约的制作者非常小心的保护了敏感区域的 storage.

解开这个合约来完成这一关.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
    */
}
```
又是让我们去获取到data[2]的数据，同时转换成bytes16,通过unlock函数来解锁。\
这个比之前让我们获取状态变量的题要稍微复杂一点。\
我们先分析这些状态变量在存储槽是怎么存储的。有个存储原则，如果是小于32字节的类型，顺序下来就会被打包进一个存储槽中，直到超过32字节，再另起一个存储槽。\
因此有这样的存储布局：\
|存储槽编号	|类型	|变量
|:------|:-----|:--------|
|slot0 | bool | locked
|slot1 | uint256 | ID
|slot2 |uint8 + uint8 + uint16| flattening，denomination，awkwardness
|slot3 | bytes32 | bytes32[0]
|slot4 | bytes32 | bytes32[1]
|slot5 | bytes32 | bytes32[2]

因为bytes32[3]是个固定长度数组，所以依次排列。\
如果是动态数组，那情况又不同，大家可以扩展研究下。\
所以我们只要根据槽号就能得到存储的值。\
32字节要转换成16字节的，那就去掉前缀“0x”,再截取左边16字节得到。
```solidity
// 此攻击在页面的console页面发起，简单快捷
// 如果有愿意搭个web3.js的环境操作可以
// 1. 获取槽位号位为5的数组数据
// 无论变量是public还是private都可以获取到
  let d = await web3.eth.getStorageAt(instance, 5)
// 2. 截取16字节后，c = bytes16(d), 这里截取的操作就不展示了，
// 调用合约的unlock()
   await contract.unlock(c)
```
### 总结
注意区分[固定]数组和[动态]数组的存储方式，\
同时要熟悉动态数组的存储槽编号的计算方式。
    
     
     
     
     
     

