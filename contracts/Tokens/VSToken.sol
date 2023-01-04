// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IPicardyVault} from "../Products/PicardyVault.sol";

contract VSToken is ERC20, Ownable {
    constructor() ERC20("Picardy Vault Token", "VSToken"){
    }

    function mint(uint _amount, address _to) external onlyOwner{
        _mint(_to, _amount);
    }

    function burn(uint _amount, address _from) external onlyOwner{
        _burn(_from, _amount);
    }

}