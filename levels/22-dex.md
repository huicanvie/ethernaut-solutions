# 22. Dex
### 原题
此题目的目标是让您破解下面的基本合约并通过价格操纵窃取资金。
一开始您可以得到10个token1和token2。合约以每个代币100个开始。
如果您设法从合约中取出两个代币中的至少一个，并让合约得到一个的“坏”的token价格，您将在此级别上取得成功。\
注意： 通常，当您使用ERC20代币进行交换时，您必须approve合约才能为您使用代币。为了与题目的语法保持一致，我们刚刚向合约本身添加了approve方法。因此，请随意使用 contract.approve(contract.address, <uint amount>) 而不是直接调用代币，它会自动批准将两个代币花费所需的金额。 请忽略SwappableToken合约。
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract Dex is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableToken is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}
```
### 分析
兄弟们来大活啦，攻击一个DEX，操纵价格。\
这只是个测试题，现实中，兄弟们还是不要做这事。\
我们只讲技术哈。\
既然要操控价格，那么我们先来分析`getSwapPrice(from, to, amount)`这个函数。\
分析价格计算公式：\
`amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)` \
也就是说两种代币的数量之比就是价格。如果是要得到“坏”的价格，\
那就大量增加某一个代币数量，造成价格巨大波动。\
我们利用`SWAP`进行交换代币。\
为什么可以达到一个坏的价格呢？\
因为此合约并没有价格保护措施，没有预言机，没有TWAP，\
可以说就是裸奔的，随便你怎么折腾。\
我们就不断使用`SWAP`来造成代币之间流动。\
在此我列了一个表格，展示多次swap中的状态变量的变化。

|swap                     |Token1（合约）|Token2（合约）|Token1（攻击者|Token2（攻击者）
|:------------------------|:-----|:--------|:---------|:---------|
|初始状态                   | 100  | 100      | 10      | 10
|swap(Token1, Token2, 10) | 110   | 90       | 0      | 20
|swap(Token2, Token1, 20) | 86   | 110      | 24      | 0
|swap(Token1, Token2, 24) | 110   | 80       | 0      | 30
|swap(Token2, Token1, 30) | 69   | 110       | 41      | 0
|swap(Token1, Token2, 41) | 110   | 45       | 0      | 65
|swap(Token2, Token1, 45) | 0   | 90       | 110      | 20

当我们把合约里的Token1变成0以后，这个价格就崩了。\
仔细的朋友肯定会好奇为什么最后一行只是交换45个呢？\
这是因为`getSwapPrice()`计算，如果是交换65个，\
`65 * 110 / 45` \
那就超过当前的余额啦，所以根据公式倒推，交换45个正合适。\
目前就得到了坏的价格了。\
我们继续往下推断。\
如果有别的客户`SWAP`会发生什么？\
1.客户存入10个Token1，他可以拿到多少个Token2呢？ \
`10 * 90 / 0`, 芭比Q了，直接revert了。\
2.客户存入10个Token2，他可以拿到多少个Token1呢？ \
`10 * 0 / 90`, 又芭比Q了，顺利执行了，但是拿到0个Token1，被合约吃啦！\
最终都是攻击者获利了。

### 总结
如果一个DEX不做好防护，等于裸奔，迟早会被掏空。\
凡在有代币交换交易的地方，都要多加小心。