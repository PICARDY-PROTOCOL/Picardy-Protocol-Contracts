// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CPToken is ERC20 {

    event TokenWrapped(address indexed account, uint indexed amount);
    event TokenUnwrapped(address indexed account, uint indexed amount);

    uint decimal = 10**18;
    constructor(string memory _name) ERC20(_name, "CPToken"){
    }

    function mint(uint _amount, address _to) external {
        uint toMint = _amount * decimal;
        _mint(_to, toMint);
    }
}