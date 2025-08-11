# 2. Fallout

### 原题
```
获得以下合约的所有权来完成这一关.
```
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Fallout {
    using SafeMath for uint256;

    mapping(address => uint256) allocations;
    address payable public owner;

    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
}
```
### 分析

要我们获取到这个合约的所有权，乍一看好像除了构造函数有所有权的设置（owner = msg.sender），没有其他函数可以修改所有权。在0.6的版本，构造函数是可以用合约名做它的函数名，同时也看到了注释/* constructor */ ，表明是使用合约名做构造函数名。如果我们大意的话，真的找不到破绽。既然要攻击，那就每个函数都仔细看。咦？这是哪个粗心鬼，1和l不分，把“Fallout”写成了“Fal1out”。这不是白送的大礼吗？这样就不是构造函数了，也没有任何限制，那我就可以直接调用了，好了，就这么简单。希望其他旧版本的合约不再有这样的“低调”错误。攻击合约，我就不写了，很简单，直接调用这个看起来像构造函数的函数吧。

```solidity

  //攻击合约省略一万字...
```