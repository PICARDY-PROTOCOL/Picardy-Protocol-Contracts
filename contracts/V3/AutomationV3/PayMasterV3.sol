// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
/// @title Paymaster V2
/// @author Joshua Obigwe

import {IRoyaltyAdapterV3} from "../AutomationV3/RoyaltyAdapterV3.sol";
import {IPicardyNftRoyaltySaleV3} from "../ProductsV3/NftRoyaltySaleV3.sol";
import {IPicardyTokenRoyaltySaleV3} from "../ProductsV3/TokenRoyaltySaleV3.sol";
import {IPicardyHub} from "../../PicardyHub.sol"; 
import {IRoyaltyAutomationRegistrarV3} from "../AutomationV3/RoyaltyAutomationRegV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract PayMasterV3 {

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
        string ticker;
    }

    IRoyaltyAutomationRegistrarV3 public i_royaltyReg;
    
    // Royalty Type 0 = NFT Royalty
    // Royalty Type 1 = Token Royalty

    constructor(address _picardyHub) {
        picardyHub = IPicardyHub(_picardyHub);
        tickerExist["ETH"] = true;
    }

    /// @notice Add a new token to the PayMaster
    /// @param _ticker The ticker of the token
    /// @param _tokenAddress The address of the token
    /// @dev Only the PicardyHub admin can call this function
    function addToken(string memory _ticker, address _tokenAddress) external {
        require(picardyHub.checkHubAdmin(msg.sender), "addToken: Un-Auth");
        require(tickerExist[_ticker] == false, "addToken: Token already Exist");
        tokenAddress[_ticker] = _tokenAddress;
        tickerExist[_ticker] = true;
    }

    /// @notice adds the picardyRegistrar address to the PayMaster
    /// @param _picardyReg The address of the picardyRegistrar
    /// @dev Only the PicardyHub admin can call this function
    function addRegAddress(address _picardyReg) external {
        require(picardyHub.checkHubAdmin(msg.sender), "addToken: Un-Auth");
        regAddress = _picardyReg;
        i_royaltyReg = IRoyaltyAutomationRegistrarV3(_picardyReg);
    }

    /// @notice Remove a token from the PayMaster
    /// @param _ticker The ticker of the token
    /// @dev Only the PicardyHub admin can call this function
    function removeToken(string memory _ticker) external {
        require(picardyHub.checkHubAdmin(msg.sender), "removeToken: Un-Auth");
        require(tickerExist[_ticker] == true, "addToken: Token does not Exist");
        delete tokenAddress[_ticker];
        delete tickerExist[_ticker];
    }

    /// @notice registers a new royalty to the paymaster
    /// @param _adapter The address for picardy royalty adapter
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param royaltyType The type of royalty (0 = NFT, 1 = Token)
    /// @param ticker The ticker of the token to be paid to the royalty holders from pay master (e.g. ETH, USDC, etc)
    /// @dev Only the picardyRegistrar can call this function on automation registration
    function addRoyaltyData(address _adapter, address _royaltyAddress, uint royaltyType, string memory ticker) external {
        require(msg.sender == regAddress, "addRoyaltyData: only picardyReg"); 
        require(royaltyType == 0 || royaltyType == 1, "addRoyaltyData: Invalid royaltyType");
        require(_adapter != address(0), "addRoyaltyData: Invalid adapter");
        require(_royaltyAddress != address(0), "addRoyaltyData: Invalid royaltyAddress");
        require(isRegistered[_royaltyAddress][_adapter] == false, "addRoyaltyData: Already registered");
        royaltyData[_royaltyAddress] = RoyaltyData(_adapter, payable(_royaltyAddress), royaltyType, ticker);
        isRegistered[_royaltyAddress][_adapter] = true;
    }

    /// @notice removes a royalty from the paymaster
    /// @param _adapter The address for picardy royalty adapter
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @dev Only the picardyRegistrar can call this function on automation cancellation
    function removeRoyaltyData(address _adapter, address _royaltyAddress) external {
        require(_adapter != address(0), "removeRoyaltyData: Invalid adapter");
        require(_royaltyAddress != address(0), "removeRoyaltyData: Invalid royaltyAddress");
        require(msg.sender == regAddress, "removeRoyaltyData: only picardyReg");
        require(isRegistered[_royaltyAddress][_adapter] == true, "removeRoyaltyData: Not registered");
        delete royaltyData[_royaltyAddress];
        delete isRegistered[_royaltyAddress][_adapter];
    }

    /// @notice updates the ETH reserve for payment of royalty splits to royalty holders
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _amount The amount of ETH to be added to the reserve
    /// @dev This function can be called by anyone as it basically just adds ETH to the royalty reserve
    function addETHReserve(address _royaltyAddress, uint256 _amount) external payable {
        require(_royaltyAddress != address(0), "addETHReserve: Invalid adapter");
        require(_amount != 0, "Amount must be greather than zero");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "addETHReserve: Not registered");
        require(msg.sender.balance >= _amount, "addETHReserve: Insufficient balance");
        require(msg.value == _amount, "addETHReserve: Insufficient ETH sent");
        royaltyReserve[_royaltyAddress][_adapter]["ETH"] += msg.value;
    }

    /// @notice updates the ERC20 reserve for payment of royalty splits to royalty holders
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token to be added to the reserve
    /// @param _amount The amount of tokens to be added to the reserve
    /// @dev This function can be called by anyone as it basically just adds tokens to the royalty reserve
    function addERC20Reserve(address _royaltyAddress, string memory _ticker, uint256 _amount) external {
        require(_royaltyAddress != address(0), "addETHReserve: Invalid adapter");
        require(_amount > 0, "Amount must be greather than zero");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "addERC20Reserve: Not registered");
        require(tokenAddress[_ticker] != address(0), "addERC20Reserve: Token not registered");
        require(IERC20(tokenAddress[_ticker]).balanceOf(msg.sender) >= _amount, "addERC20Reserve: Insufficient balance");
        (bool success) = IERC20(tokenAddress[_ticker]).transferFrom(msg.sender, address(this), _amount);
        require(success, "addERC20Reserve: Transfer failed");
        royaltyReserve[_royaltyAddress][_adapter][_ticker] += _amount;
    }

    /// @notice withdraws the ETH reserve for payment of royalty splits to royalty holders
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _amount The amount of ETH to be withdrawn from the reserve
    /// @dev This function can only be called by the royalty contract admin
    function withdrawReserve(address _royaltyAddress, string memory _ticker, uint256 _amount) external {
        require(_royaltyAddress != address(0), "withdrawReserve: Invalid adapter");
        require(_amount > 0, "Amount must be greather than zero");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "withdrawReserve: Not registered");
        require(msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "withdrawReserve: not royalty admin");
        uint balance = royaltyReserve[_royaltyAddress][_adapter][_ticker];
        require(balance >= _amount, "withdrawReserve: Insufficient balance");
        royaltyReserve[_royaltyAddress][_adapter][_ticker] -= _amount;
        if(keccak256(abi.encodePacked(_ticker)) == keccak256(abi.encodePacked("ETH"))){
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "withdrawReserve: withdraw failed");
        }else{
            (bool success) = IERC20(tokenAddress[_ticker]).transfer(msg.sender, _amount);
            require(success, "withdrawReserve: Transfer failed");
        }
    }

    /// @notice sends the royalty payment to the royalty sale contract to be distributed to the royalty holders
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token to be sent to the royalty sales contract
    /// @param _amount The amount to be sent to the royalty sales contract
    /// @dev This function can only be called by picardy royalty adapter, With the amount being the return form chainlink node.
    /// @dev The amount is then multiplied by the royalty percentage to get the amount to be sent to the royalty sales contract
    /// @dev if the reserve balance of the token is less than the amount to be sent, the amount is added to the pending payments
    function sendPayment(address _royaltyAddress, string memory _ticker, uint256 _amount) external  returns(bool){
        require(_royaltyAddress != address(0), "sendPayment: Invalid royaltyAddress");
        require(tickerExist[_ticker] == true, "sendPayment: Token not registered");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "sendPayment: Not registered");
        require(msg.sender == _adapter, "sendPayment: Un-Auth");
        
        uint balance = royaltyReserve[_royaltyAddress][_adapter][_ticker];
        uint royaltyType = royaltyData[_royaltyAddress].royaltyType;
        uint percentageToBips = _royaltyPercentage(_royaltyAddress, royaltyType);

        uint toSend = (_amount * percentageToBips) / 10000;
        
        if(balance < _amount){
            
            royaltyPending[_royaltyAddress][_adapter][_ticker] += toSend;
            emit PaymentPending(_royaltyAddress, _ticker, toSend);
        
        } else {
            
            if(keccak256(bytes(_ticker)) == keccak256(bytes("ETH"))){
            royaltyReserve[_royaltyAddress][_adapter][_ticker] -= toSend;
            royaltyPaid[_royaltyAddress][_adapter][_ticker] += toSend;
            (bool success, ) = payable(_royaltyAddress).call{value: toSend}("");
            require (success);
            
            } else {
                
                require(tokenAddress[_ticker] != address(0), "sendPayment: Token not registered");
                require(royaltyReserve[_royaltyAddress][_adapter][_ticker] >= toSend, "low reserve balance");
                if(royaltyType == 0){
                    require(IRoyaltyAdapterV3(_adapter).checkIsValidSaleAddress(_royaltyAddress) == true, "Royalty address invalid");
                    royaltyReserve[_royaltyAddress][_adapter][_ticker] -= toSend;
                    IPicardyNftRoyaltySaleV3(_royaltyAddress).updateRoyalty(toSend, tokenAddress[_ticker]);
                    royaltyPaid[_royaltyAddress][_adapter][_ticker] += toSend;
                } else if(royaltyType == 1){
                    require(IRoyaltyAdapterV3(_adapter).checkIsValidSaleAddress(_royaltyAddress) == true, "Royalty address invalid");
                    royaltyReserve[_royaltyAddress][_adapter][_ticker] -= toSend;
                    IPicardyTokenRoyaltySaleV3(_royaltyAddress).updateRoyalty(toSend, tokenAddress[_ticker]);
                    royaltyPaid[_royaltyAddress][_adapter][_ticker] += toSend;
                }

                (bool success) = IERC20(tokenAddress[_ticker]).transfer(_royaltyAddress, toSend);
                require (success);    
            }
        }
        emit RoyaltyPaymentSent(_royaltyAddress, _ticker, toSend); 
        return true;
    }

    /// @notice gets the royalty percentage from the royalty sales contract and converts it to bips
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _royaltyType The type of royalty sales contract
    /// @dev This is internal view function and doesnt write to state.
    function _royaltyPercentage(address _royaltyAddress, uint _royaltyType) internal view returns(uint){
        require(_royaltyAddress != address(0), "getRoyaltyPercentage: Invalid royaltyAddress");
        require(_royaltyType == 0 || _royaltyType == 1, "getRoyaltyPercentage: Invalid royaltyType");
        uint percentageToBips;
        if (_royaltyType == 0){
            uint percentage = IPicardyNftRoyaltySaleV3(_royaltyAddress).getRoyaltyPercentage();
            percentageToBips = percentage * 100;
        } else if (_royaltyType == 1){
            uint percentage = IPicardyTokenRoyaltySaleV3(_royaltyAddress).getRoyaltyPercentage();
            percentageToBips = percentage * 100;
        }

        return percentageToBips;
    }

    /// @notice Refunds the pending unpaid royalty to the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token to be sent to the royalty sales contract
    /// @param _amount The amount to be sent to the royalty sales contract
    /// @dev this function should be called by the royalty sale contract admin
    function refundPending(address _royaltyAddress, string memory _ticker, uint256 _amount) external {
        require(_royaltyAddress != address(0), "refundPending: Invalid adapter");
        require(msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "withdrawReserve: not royalty admin");
        require(tickerExist[_ticker] == true, "refundPending: Token not registered");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "refundPending: Not registered");
        require(royaltyReserve[_royaltyAddress][_adapter][_ticker] >= _amount, "refundPending: low reserve balance");
        require(_amount <= royaltyPending[_royaltyAddress][_adapter][_ticker], "refundPending: amount is greather than pending royalty");
        
        uint royaltyType = royaltyData[_royaltyAddress].royaltyType;
        
        if(keccak256(bytes(_ticker)) == keccak256(bytes("ETH"))){
            
            royaltyReserve[_royaltyAddress][_adapter][_ticker] -= _amount;
            royaltyPending[_royaltyAddress][_adapter][_ticker] -= _amount;
            royaltyPaid[_royaltyAddress][_adapter][_ticker] += _amount;
            (bool success, ) = payable(_royaltyAddress).call{value: _amount}("");
            require (success);
        
        } else {
            
            require(tokenAddress[_ticker] != address(0), "sendPayment: Token not registered");
            require(royaltyReserve[_royaltyAddress][_adapter][_ticker] >= _amount, "low reserve balance");
            
            if(royaltyType == 0){
                require(IRoyaltyAdapterV3(_adapter).checkIsValidSaleAddress(_royaltyAddress) == true, "Royalty address invalid");
                royaltyReserve[_royaltyAddress][_adapter][_ticker] -= _amount;
                royaltyPending[_royaltyAddress][_adapter][_ticker] -= _amount;
                royaltyPaid[_royaltyAddress][_adapter][_ticker] += _amount;
                IPicardyNftRoyaltySaleV3(_royaltyAddress).updateRoyalty(_amount, tokenAddress[_ticker]);
            } else if(royaltyType == 1){
                require(IRoyaltyAdapterV3(_adapter).checkIsValidSaleAddress(_royaltyAddress) == true, "Royalty address invalid");
                royaltyReserve[_royaltyAddress][_adapter][_ticker] -= _amount;
                royaltyPending[_royaltyAddress][_adapter][_ticker] -= _amount;
                royaltyPaid[_royaltyAddress][_adapter][_ticker] += _amount;
                IPicardyTokenRoyaltySaleV3(_royaltyAddress).updateRoyalty(_amount, tokenAddress[_ticker]);
            }
            
            (bool success) = IERC20(tokenAddress[_ticker]).transfer(_royaltyAddress, _amount);
            require (success);    
        }

        emit PendingRoyaltyRefunded(_royaltyAddress, _ticker, _amount);
    }

    /// @notice Gets the ETH royalty reserve balance of the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @dev This is external view function and doesnt write to state.
    function getETHReserve(address _royaltyAddress) external view returns (uint256) {
        address _adapter = royaltyData[_royaltyAddress].adapter;
        return royaltyReserve[_royaltyAddress][_adapter]["ETH"];
    }

    /// @notice Gets the ERC20 royalty reserve balance for the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token
    /// @dev This is external view function and doesnt write to state.
    function getERC20Reserve(address _royaltyAddress, string memory _ticker) external view returns (uint256) {
        address _adapter = royaltyData[_royaltyAddress].adapter;
        return royaltyReserve[_royaltyAddress][_adapter][_ticker];
    }

    /// @notice Gets the royalty pending balance for the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token
    /// @dev This is external view function and doesnt write to state.
    function getPendingRoyalty(address _royaltyAddress, string memory _ticker) external view returns (uint256) {
        address _adapter = royaltyData[_royaltyAddress].adapter;
        return royaltyPending[_royaltyAddress][_adapter][_ticker];
    }

    /// @notice returns the amount of royalty that has paid to the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token
    /// @dev This is external view function and doesnt write to state.
    function getRoyaltyPaid(address _royaltyAddress, string memory _ticker) external view returns (uint256) {
        address _adapter = royaltyData[_royaltyAddress].adapter;
        return royaltyPaid[_royaltyAddress][_adapter][_ticker];
    }

    /// @notice gets the royalty address of the token by ticker
    /// @param _ticker The ticker of the token
    /// @dev This is external view function and doesnt write to state.
    function getTokenAddress(string memory _ticker) external view returns (address) {
        return tokenAddress[_ticker];
    }

    /// @notice gets the picardy automation registrar address
    /// @dev This is external view function and doesnt write to state.
    function getPicardyReg() external view returns(address){
        return regAddress;
    }

    /// @notice checks that the ticker is registered
    function checkTickerExist(string memory _ticker) external view returns(bool){
        return tickerExist[_ticker];
    }

}

interface IPayMaster {
    function getERC20Reserve(address _royaltyAddress, string memory _ticker) external view returns (uint256);
    function getETHReserve(address _royaltyAddress) external view returns (uint256);
    function getRoyaltyPaid(address _royaltyAddress, string memory _ticker) external view returns (uint256);
    function getPendingRoyalty(address _royaltyAddress, string memory _ticker) external view returns (uint256);
    function addETHReserve(address _royaltyAddress, uint256 _amount) external payable; 
    function addERC20Reserve(address _royaltyAddress, string memory _ticker, uint256 _amount) external ;
    function sendPayment(address _royaltyAddress, string memory _ticker, uint256 _amount) external  returns(bool);
    function checkTickerExist(string memory _ticker) external view returns(bool);
    function getPicardyReg() external view returns(address);
    function addRoyaltyData(address _adapter, address _royaltyAddress, uint royaltyType, string memory ticker) external; 
    function removeRoyaltyData(address _adapter, address _royaltyAddress) external; 
    function getTokenAddress(string memory _ticker) external view returns (address);
    function refundPending(address _royaltyAddress, string memory _ticker, uint256 _amount) external;
    function withdrawReserve(address _royaltyAddress, string memory _ticker, uint256 _amount) external;
    function removeToken(string memory _ticker) external;
    function addRegAddress(address _picardyReg) external;
    function addToken(string memory _ticker, address _tokenAddress) external;
}