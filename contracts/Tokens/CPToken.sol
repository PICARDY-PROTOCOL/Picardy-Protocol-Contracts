// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CPToken is ERC20 {

    uint decimal = 10**18;
    address public owner;
    address[] holders;

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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        super.transfer(recipient, amount);
        holders.push(recipient);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public  override returns (bool) {
        super.transferFrom(sender, recipient, amount);
        holders.push(recipient);
        return true;
    }

    function getHolders() public view returns (address[] memory) {
        return holders;
    }
}