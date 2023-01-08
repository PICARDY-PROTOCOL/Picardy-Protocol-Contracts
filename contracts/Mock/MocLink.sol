// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MocLink is ERC20, Ownable {

    uint decimal = 10**18;
    constructor() ERC20("Test Link", "mLINK"){
    }

    function mint(uint _amount , address _to) public {
        uint toSend = _amount*decimal;
        _mint(_to, toSend);
    }
}