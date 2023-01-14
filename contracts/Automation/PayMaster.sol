
// can update pending payment

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import {IRoyaltyAdapter} from "../Automation/RoyaltyAdapter.sol";
import {ITokenRoyaltyAdapter} from "../Automation/TokenRoyaltyAdapter.sol";
import {IPicardyNftRoyaltySale} from "../Products/NftRoyaltySale.sol";
import {IPicardyTokenRoyaltySale} from "../Products/TokenRoyaltySale.sol";
import {IPicardyHub} from "../PicardyHub.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract PayMaster {

    event PaymentPending(address indexed royaltyAddress, string indexed ticker, uint indexed amount);
    event PendingRoyaltyRefunded (address indexed royaltyAddress, string indexed ticker, uint indexed amount);
    event RoyaltyPaymentSent(address indexed royaltyAddress, string indexed ticker, uint indexed amount);

    IPicardyHub public picardyHub;
    address private regAddress;

    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyReserve; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyReserve
    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyPending; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyPending
    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyPaid; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyPaid
    
    mapping (address => mapping (address => bool)) public isRegistered; // royaltyAdapter -> royaltyAddress = isRegistered
    mapping (address => RoyaltyData) public royaltyData; // royaltyAdapter = RoyaltyData
    mapping (string => address) public tokenAddress;
    mapping (string => bool) tickerExist;

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
        require(picardyHub.checkHubAdmin(msg.sender), "addToken: Un-Auth");
        require(tickerExist[_ticker] == false, "addToken: Token already Exist");
        tokenAddress[_ticker] = _tokenAddress;
        tickerExist[_ticker] = true;
    }

    function addRegAddress(address _picardyReg) external {
        require(picardyHub.checkHubAdmin(msg.sender), "addToken: Un-Auth");
        regAddress = _picardyReg;
    }

    function removeToken(string memory _ticker) public {
        require(picardyHub.checkHubAdmin(msg.sender), "removeToken: Un-Auth");
        require(tickerExist[_ticker] == true, "addToken: Token does not Exist");
        delete tokenAddress[_ticker];
        delete tickerExist[_ticker];
    }

    function addRoyaltyData(address _adapter, address _royaltyAddress, uint royaltyType) public {
        require(msg.sender == regAddress, "addRoyaltyData: only picardyReg");
        require(isRegistered[_adapter][_royaltyAddress] == false, "addRoyaltyData: Already registered");
        royaltyData[_adapter] = RoyaltyData(_adapter, payable(_royaltyAddress), royaltyType);
        isRegistered[_adapter][_royaltyAddress] = true;
    }

    function addETHReserve(address _adapter, uint256 _amount) public payable {
        require(_amount > 0, "Amount must be greather than zero");
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        require(isRegistered[_adapter][_royaltyAddress] == true, "addETHReserve: Not registered");
        require(msg.sender.balance >= _amount, "addETHReserve: Insufficient balance");
        require(msg.value == _amount, "addETHReserve: Insufficient ETH sent");
        royaltyReserve[_adapter][_royaltyAddress]["ETH"] += msg.value;
    }

    function addERC20Reserve(address _adapter, string memory _ticker, uint256 _amount) public {
        require(_amount > 0, "Amount must be greather than zero");
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        require(isRegistered[_adapter][_royaltyAddress] == true, "addERC20Reserve: Not registered");
        require(tokenAddress[_ticker] != address(0), "addERC20Reserve: Token not registered");
        require(IERC20(tokenAddress[_ticker]).balanceOf(msg.sender) >= _amount, "addERC20Reserve: Insufficient balance");
        IERC20(tokenAddress[_ticker]).transferFrom(msg.sender, address(this), _amount);
        royaltyReserve[_adapter][_royaltyAddress][_ticker] += _amount;
    }

    function sendPayment(address _adapter, string memory _ticker, uint256 _amount) public {
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        require(isRegistered[_adapter][_royaltyAddress] == true, "sendPayment: Not registered");
        require(msg.sender == _adapter, "sendPayment: Un-Auth (adapter)");
        uint royaltyType = royaltyData[_adapter].royaltyType;
        uint balance = royaltyReserve[_adapter][_royaltyAddress][_ticker];
        if(balance < _amount){
            royaltyPending[_adapter][_royaltyAddress][_ticker] += _amount;
            emit PaymentPending(_royaltyAddress, _ticker, _amount);
        } else {
            if(keccak256(bytes(_ticker)) == keccak256(bytes("ETH"))){
            royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
            royaltyPaid[_adapter][_royaltyAddress][_ticker] += _amount;
            (bool success, ) = payable(_royaltyAddress).call{value: _amount}("");
            require (success);
            } else {
                require(tokenAddress[_ticker] != address(0), "sendPayment: Token not registered");
                if(royaltyType == 0){
                    require(IRoyaltyAdapter(_adapter).getRoyaltySaleAddress() == _royaltyAddress, "Royalty address invalid");
                    royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
                    royaltyPaid[_adapter][_royaltyAddress][_ticker] += _amount;
                    IPicardyNftRoyaltySale(_royaltyAddress).updateRoyalty(_amount);
                } else if(royaltyType == 1){
                    require(ITokenRoyaltyAdapter(_adapter).getRoyaltySaleAddress() == _royaltyAddress, "Royalty address invalid");
                    royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
                    royaltyPaid[_adapter][_royaltyAddress][_ticker] += _amount;
                    IPicardyTokenRoyaltySale(_royaltyAddress).updateRoyalty(_amount);
                }
                (bool success) = IERC20(tokenAddress[_ticker]).transfer(_royaltyAddress, _amount);
                require (success);    
            }
        }

        emit RoyaltyPaymentSent(_royaltyAddress, _ticker, _amount); 
    }

    function refundPending(address _adapter, string memory _ticker, uint256 _amount) public {
        address _royaltyAddress = royaltyData[_adapter].royaltyAddress;
        require(isRegistered[_adapter][_royaltyAddress] == true, "sendPayment: Not registered");
        require(royaltyReserve[_adapter][_royaltyAddress][_ticker] >= _amount, "low reserve balance");
        require(_amount <= royaltyPending[_adapter][_royaltyAddress][_ticker], "amount is greather than pending royalty");
        uint royaltyType = royaltyData[_adapter].royaltyType;
        if(keccak256(bytes(_ticker)) == keccak256(bytes("ETH"))){
            royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
            royaltyPending[_adapter][_royaltyAddress][_ticker] -= _amount;
            royaltyPaid[_adapter][_royaltyAddress][_ticker] += _amount;
            (bool success, ) = payable(_royaltyAddress).call{value: _amount}("");
            require (success);
        } else {
            require(tokenAddress[_ticker] != address(0), "sendPayment: Token not registered");
            if(royaltyType == 0){
                require(IRoyaltyAdapter(_adapter).getRoyaltySaleAddress() == _royaltyAddress, "Royalty address invalid");
                 royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
                royaltyPending[_adapter][_royaltyAddress][_ticker] -= _amount;
                royaltyPaid[_adapter][_royaltyAddress][_ticker] += _amount;
                IPicardyNftRoyaltySale(_royaltyAddress).updateRoyalty(_amount);
            } else if(royaltyType == 1){
                require(ITokenRoyaltyAdapter(_adapter).getRoyaltySaleAddress() == _royaltyAddress, "Royalty address invalid");
                 royaltyReserve[_adapter][_royaltyAddress][_ticker] -= _amount;
                royaltyPending[_adapter][_royaltyAddress][_ticker] -= _amount;
                royaltyPaid[_adapter][_royaltyAddress][_ticker] += _amount;
                IPicardyTokenRoyaltySale(_royaltyAddress).updateRoyalty(_amount);
            }
            (bool success) = IERC20(tokenAddress[_ticker]).transfer(_royaltyAddress, _amount);
            require (success);    
        }

        emit PendingRoyaltyRefunded(_royaltyAddress, _ticker, _amount);
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

    function getTokenAddress(string memory _ticker) public view returns (address) {
        return tokenAddress[_ticker];
    }

    function getPicardyReg() external view returns(address){
        return regAddress;
    }

    function checkTickerExist(string memory _ticker) external view returns(bool){
        return tickerExist[_ticker];
    }

}

interface IPayMaster {
    function getRoyaltyReserve(address _adapter, string memory _ticker) external view returns (uint256);
    function getRoyaltyPending(address _adapter, string memory _ticker) external view returns (uint256);
    function getRoyaltyPaid(address _adapter, string memory _ticker) external view returns (uint256);
    function getTokenAddress(string memory _ticker) external view returns (address);
    function addRoyaltyReserve(address _adapter,string memory _ticker, uint256 _amount) external payable;
    function addRoyaltyData(address _adapter, address _royaltyAddress, uint royaltyType) external;
    function sendPayment(address _adapter, string memory _ticker, uint256 _amount) external;
    function checkTickerExist(string memory _ticker) external view returns(bool);
}