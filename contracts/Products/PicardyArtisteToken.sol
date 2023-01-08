// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IArtisteTokenFactory} from "../Factory/ArtisteTokenFactory.sol";
contract PicardyArtisteToken is ERC20, Ownable {

    uint public maxSupply;
    uint public cost;
    address factory;
    constructor(uint _maxSupply, string memory _name, string memory _symbol, address _creator, address _factory, uint _cost) ERC20(_name, _symbol){
        maxSupply = _maxSupply;
        factory = _factory;
        cost = _cost;
        transferOwnership(_creator); 
    }

    function mint(uint _amount, address _to) external payable {
        require (_amount < maxSupply, "you cannot mint more than the maxSupply");
        require (msg.sender.balance >= _amount * cost, "Balance low");
        require(msg.value >= _amount * cost, "value passed less than amount");
        _mint(_to, _amount);
    }

    function withdraw () external onlyOwner{
        (address royaltyAddress, uint royaltyPercentage) = IArtisteTokenFactory(factory).getRoyaltyDetails();
        uint balance = address(this).balance;
        uint txFee = (balance * royaltyPercentage) / 100;
        uint toWithdraw = balance - txFee;
        address _owner = payable(owner());
        (bool hs, ) = payable(royaltyAddress).call{value: txFee}("");
        (bool os, ) = _owner.call{value: toWithdraw}("");
        require(hs);
        require(os);
    }
}