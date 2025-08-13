# Ethernaut关卡通关攻略与详细解析

> 以太坊智能合约挑战题（Ethernaut）全关卡思路讲解、漏洞分析与破解代码  
> 作者：Canvie

---

## 项目简介

本项目整理了[Ethernaut](https://ethernaut.openzeppelin.com/)所有关卡的解题过程，覆盖每一关的思路、漏洞根源、分析细节、攻防代码和相关安全知识点。旨在帮助智能合约开发者、攻防研究者深入理解 Solidity 安全、以太坊合约漏洞原理和实战技巧。

Ethernaut 是由 OpenZeppelin 官方推出的一款以太坊智能合约安全闯关游戏，涵盖了常见与高阶的攻击手法（如重入、越权、整数溢出、合约自毁、委托调用等），是区块链安全入门与进阶的重要实战教程。

---

## 目录

|关卡编号	|题目名	|分析与代码
|:-------|:-----|:--------|
| 1	| Fallback	      |[点此前往](levels/1-fallback.md)
| 2	| Fallout	        |[点此前往](levels/2-fallout.md)

全部关卡列表见：[LEVELS.md](LEVELS.md)


## 扩展阅读

Ethernaut官方链接
Solidity官方文档链接
相关安全论文/社区文章

---

## 使用方法

1. 克隆本仓库 `git clone https://github.com/huicanvie/ethernaut-solutions.git`
2. 阅读 `/levels` 文件夹下各关卡详细讲解
3. 按需参考 `/scripts` 下的攻击脚本或本地测试复现
4. 推荐搭配 [Ethernaut官网](https://ethernaut.openzeppelin.com/) 线上实战演练
5. 代码均在remix测试通过

---

## 贡献指南

- 欢迎任何形式的补充、修正和经验分享，直接发起 Pull Request 或 Issue 与我交流
- 可贡献包括：更详细的漏洞分析、更优代码、更丰富参考资料、英文翻译、图片说明等

---

## 致谢/引用资源

- [Ethernaut](https://ethernaut.openzeppelin.com/) by OpenZeppelin
- [Solidity官方文档](https://docs.soliditylang.org/zh-cn/latest/introduction-to-smart-contracts.html)
- 以及所有区块链安全社区前辈的研究与教程

---

## 免责声明

本仓库仅用于技术学习与安全研究交流，文中涉及的所有漏洞与代码严禁用于非授权环境或非法行为。请自觉遵守行业规范和法律法规！

---

