// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CPToken is ERC20 {

    event TokenWrapped(address indexed account, uint indexed amount);
    event TokenUnwrapped(address indexed account, uint indexed amount);

    uint decimal = 10**18;
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "not approved");
        _;
    }

    constructor(string memory _name, address _owner) ERC20(_name, "CPToken"){
        owner = _owner;
    }

    function mint(uint _amount, address _to) external onlyOwner {
        uint toMint = _amount * decimal;
        _mint(_to, toMint);
    }
}