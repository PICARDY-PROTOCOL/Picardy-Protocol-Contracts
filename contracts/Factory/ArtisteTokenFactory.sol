/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/PicardyArtisteToken.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";
contract ArtisteTokenFactory is Context {

   event NewArtisteTokenCreated(uint tokenId, uint totalAmount, address tokenAddress);
   event RoyaltyDetailsUpdated(uint percentage, address royaltyAddress);
    address picardyHub;

    struct ArtisteToken{
        uint artisteTokenId;
        uint totalAmount;
        string name;
        string symbol;
        address creator;
        address artisteTokenAddress;
        uint cost;
    }

    struct RoyaltyDetails{
        uint royaltyPercentage;
        address royaltyAddress;
    }
    RoyaltyDetails royaltyDetails;

    mapping(string => mapping(string => address)) public tokenAddressMap;
    mapping(uint => ArtisteToken) artisteTokenMap;

    uint artisteTokenId = 1;
    constructor(address _picardyHub) {
        picardyHub = _picardyHub;
    }
    
    /**
        @dev Creats an ERC20 contract to the caller
        @param _totalAmount The maximum suppyly of the token
        @param _name Token name 
        @param _symbol Token symbol
     */
    function createArtisteToken(uint _totalAmount, string memory _name, string memory _symbol, uint _cost) external { 
        uint newTokenId = artisteTokenId;
         PicardyArtisteToken token = new PicardyArtisteToken(_totalAmount, _name, _symbol, _msgSender(), address(this), _cost);
         ArtisteToken memory newArtisteToken = ArtisteToken(newTokenId, _totalAmount, _name, _symbol, _msgSender(), address(token), _cost);
         tokenAddressMap[_name][_symbol] = address(token);
         artisteTokenMap[newTokenId] = newArtisteToken;
         artisteTokenId++;
         emit NewArtisteTokenCreated(newTokenId, _totalAmount, address(token));
    }

    function getHubAddress() external view returns (address){
        return picardyHub;
    }

    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()), "Not Hub Admin");
        address royaltyAddress = IPicardyHub(picardyHub).getRoyaltyAddress();
        RoyaltyDetails memory newRoyaltyDetails = RoyaltyDetails(_royaltyPercentage, royaltyAddress);
        royaltyDetails = newRoyaltyDetails;
        emit RoyaltyDetailsUpdated(_royaltyPercentage, royaltyAddress);
    }

    function getRoyaltyDetails() external view returns (address, uint){
        address royaltyAddress = royaltyDetails.royaltyAddress;
        uint royaltyPercentage = royaltyDetails.royaltyPercentage;
        return(royaltyAddress, royaltyPercentage);
    }

    function getTokenAddress(string calldata _name, string memory _symbol) external view returns (address){
        return tokenAddressMap[_name][_symbol];
    }

}

interface IArtisteTokenFactory {
    function getRoyaltyDetails() external view returns (address, uint);
    function getHubAddress() external view returns (address);
}