// has mapping of balances for differen tokens, with adapter address and royalty address *
// hubadmin can add and remove new token *
// should send only token accepted by the royalty contract 
// can update pendend payment

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import {IRoyaltyAdapter} from "../Automation/RoyaltyAdapter.sol";
import {ITokenRoyaltyAdapter} from "../Automation/TokenRoyaltyAdapter.sol";
import {ITokenRoyaltySale} from "../Products/TokenRoyaltySale.sol";
import {INftRoyaltySale} from "../Products/NftRoyaltySale.sol";
import {IPicardyHub} from "../PicardyHub.sol";  

contract PaymentMaster {

    IPicardyHub public picardyHub;

    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyReserve; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyReserve
    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyPending; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyPending
    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyPaid; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyPaid
    
    mapping (address => mapping (address => bool)) public isRegistered; // royaltyAdapter -> royaltyAddress = isRegistered
    mapping (address => RoyaltyData) public royaltyData; // royaltyAdapter = RoyaltyData
    mapping (string => address) public tokenAddress;

    struct RoyaltyData {
        address adapter;
        address payable royaltyAddress;
        uint royaltyType;
    }
    
    // Royalty Type 0 = NFT Royalty
    // Royalty Type 1 = Token Royalty

    constructor(address _picardyHub) {
        picardyHub = IPicardyHub(_picardyHub);
    }

    function addToken(string memory _ticker, address _tokenAddress) public {
        require(picardyHub.isHubAdmin(msg.sender), "addToken: Un-Auth");
        tokenAddress[_ticker] = _tokenAddress;
    }

    function removeToken(string memory _ticker) public {
        require(picardyHub.isHubAdmin(msg.sender), "removeToken: Un-Auth");
        delete tokenAddress[_ticker];
    }

    function addRoyaltyData(address _adapter, address _royaltyAddress, uint royaltyType) public {
        require(isRegistered[_adapter][_royaltyAddress] == false, "addRoyaltyData: Already registered");
        royaltyData[_adapter] = RoyaltyData(_adapter, payable(_royaltyAddress), royaltyType);
        isRegistered[_adapter][_royaltyAddress] = true;
    }

    function addRoyaltyReserve(address _adapter,string memory _ticker, uint256 _amount) public payable {
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        require(isRegistered[_adapter][_royaltyAddress] == true, "addRoyaltyReserve: Not registered");
        if(_ticker == "ETH"){
            require(msg.sender.balance >= _amount, "addRoyaltyReserve: Insufficient balance");
            royaltyReserve[_adapter][_royaltyAddress][_ticker] += msg.value;
        } else {
            require(tokenAddress[_ticker] != address(0), "addRoyaltyReserve: Token not registered");
            require(IERC20(tokenAddress[_ticker]).balanceOf(msg.sender) >= _amount, "addRoyaltyReserve: Insufficient balance");
            IERC20(tokenAddress[_ticker]).transfer(address(this), _amount);
            royaltyReserve[_adapter][_royaltyAddress][_ticker] += _amount;
        }
         
    }

    function sendPayment(address _adapter, string memory _ticker, uint256 _amount) public payable {
        require(isRegistered[_adapter][_royaltyAddress] == true, "sendPayment: Not registered");
        require(msg.sender == _adapter, "sendPayment: Un-Auth (adapter)");
        uint royaltyType = royaltyData[_adapter].royaltyType;
        uint balance = royaltyReserve[_adapter][_royaltyAddress][_ticker];
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        if(balance < _amount){
            royaltyPending[_adapter][_royaltyAddress][_ticker] += amount;
            emit PaymentPending(_royaltyAddress, _ticker, _amount);
        } else {
            if(_ticker == "ETH"){
            royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
            royaltyPending[_adapter][_royaltyAddress][_ticker] += _amount;
            (bool success, ) = payable(_royaltyAddress).call{value: _amount}("");
            require (success);
            } else {
                require(tokenAddress[_ticker] != address(0), "sendPayment: Token not registered");
                if(royaltyType == 0){
                    require(IRoyaltyAdapter(_adapter).getRoyaltySaleAddress() == _royaltyAddress, "Royalty address invalid");
                    royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
                    royaltyPaid[_adapter][_royaltyAddress][_ticker] += _amount;
                    IRoyaltyAdapter(_adapter).updateRoyalty(_amount);
                    (bool success) = IERC20(tokenAddress[_ticker]).transfer(_royaltyAddress, _amount);
                    require (success);
                } else if(royaltyType == 1){
                    require(ITokenRoyaltyAdapter(_adapter).getRoyaltySaleAddress() == _royaltyAddress, "Royalty address invalid");
                    royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
                    royaltyPaid[_adapter][_royaltyAddress][_ticker] += _amount;
                    ITokenRoyaltyAdapter(_adapter).updateRoyalty(_amount);
                    (bool success) = IERC20(tokenAddress[_ticker]).transfer(_royaltyAddress, _amount);
                    require (success);
                }
                
            }
        }
      
    }

    function getRoyaltyReserve(address _adapter, string memory _ticker) public view returns (uint256) {
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        return royaltyReserve[_adapter][_royaltyAddress][_ticker];
    }

    function getRoyaltyPending(address _adapter, string memory _ticker) public view returns (uint256) {
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        return royaltyPending[_adapter][_royaltyAddress][_ticker];
    }

    function getRoyaltyPaid(address _adapter, string memory _ticker) public view returns (uint256) {
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        return royaltyPaid[_adapter][_royaltyAddress][_ticker];
    }

}