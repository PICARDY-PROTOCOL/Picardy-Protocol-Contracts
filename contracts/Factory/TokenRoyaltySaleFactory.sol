

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/TokenRoyaltySale.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";

/// @title Token Royalty Sale Factory
/// @author Blok_hamster  
/// @notice Used to create token royalty sale contracts.
contract TokenRoyaltySaleFactory is Context {
    
    event TokenRoyaltyCreated (address indexed creator, address indexed tokenRoyaltyAddress, uint indexed royaltyId);
    event RoyaltyDetailsUpdated(uint indexed percentage, address indexed royaltyAddress);

    struct TokenRoyaltyDetails{ 
        uint tokenRoyaltyId;
        uint askAmount;
        uint returnPercentage;
        address tokenRoyaltyAddress;
    }

    /// @notice struct holds royalty details for the hub
    struct RoyaltyDetails{
        uint royaltyPercentage;
        address royaltyAddress;
    }
    RoyaltyDetails royaltyDetails;

    mapping(uint => address) public tokenRoyaltyDetailsIdMap;
    mapping(uint => TokenRoyaltyDetails) public tokenRoyaltyDetailsMap;
    address picardyHub;
    address linkToken;
    uint tokenRoyaltyId = 1;
   constructor (address _picardyHub, address _linkToken){
        picardyHub = _picardyHub;
        linkToken = _linkToken;
    }


    ///@dev Creats A ERC20 token royalty sale contract 
    ///@param _askAmount The total askinng amount for royalty
    ///@param _returnPercentage Percentage of royalty to sell
    function createTokenRoyalty(uint _askAmount, uint _returnPercentage, string memory creatorName, string memory name) external returns(address){
        uint newTokenRoyaltyId = tokenRoyaltyId;
        TokenRoyaltySale tokenRoyalty = new TokenRoyaltySale(_askAmount, _returnPercentage, address(this), _msgSender(), creatorName, name);
        TokenRoyaltyDetails memory newTokenRoyaltyDetails = TokenRoyaltyDetails(newTokenRoyaltyId, _askAmount, _returnPercentage, address(tokenRoyalty));
        tokenRoyaltyDetailsIdMap[newTokenRoyaltyId] = address(tokenRoyalty);
        tokenRoyaltyDetailsMap[newTokenRoyaltyId] = newTokenRoyaltyDetails;
        tokenRoyaltyId++;
        emit TokenRoyaltyCreated(_msgSender(), address(tokenRoyalty), newTokenRoyaltyId);
        return(address(tokenRoyalty));
    }

    /// @notice the function is used to update the royalty percentage.
    /// @dev only hub admin can call this function 
    /// @param _royaltyPercentage the amount in percentage the hub takes.
    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()) == true, "Not Hub Admin");
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

    function getTokenRoyaltyAddress(uint _tokenRoyaltyId) external view returns(address){
        return tokenRoyaltyDetailsIdMap[_tokenRoyaltyId];
    }

    function getHubAddress() external view returns (address){
        return picardyHub;
    }

    function getLinkToken() external view returns(address){
        return linkToken;
    }
}

interface ITokenRoyaltySaleFactory{
    function getRoyaltyDetails() external view returns (address, uint);
    function getHubAddress() external view returns (address);
    function getLinkToken() external view returns(address);
}