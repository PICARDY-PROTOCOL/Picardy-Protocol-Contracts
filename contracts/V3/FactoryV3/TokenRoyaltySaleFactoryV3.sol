// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

/// @title TokenRoyaltySaleFactoryV2
/// @author Joshua Obigwe 

import "../ProductsV3/TokenRoyaltySaleV3.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {IPicardyHub} from "../../PicardyHub.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

 
contract TokenRoyaltySaleFactoryV3 is Context, ReentrancyGuard {

    address tokenRoyaltySaleImplementation;
    
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

    mapping(address => TokenRoyaltyDetails) public tokenRoyaltyDetailsMap;
    mapping(string => mapping (string => address)) royaltySaleAddress;
    address picardyHub;
    address linkToken;
    uint tokenRoyaltyId = 1;
   constructor (address _picardyHub, address _linkToken, address _tokenRoyaltySaleImpl){
        picardyHub = _picardyHub;
        linkToken = _linkToken;
        tokenRoyaltySaleImplementation = _tokenRoyaltySaleImpl;
    }

    ///@param _askAmount The total askinng amount for royalty
    ///@param _returnPercentage Percentage of royalty to sell
    ///@dev Creats A ERC20 token royalty sale. contract is created using the Clones library
    function createTokenRoyalty(uint _askAmount, uint _returnPercentage, string memory creatorName, string memory name, address creator, string calldata symbol) external nonReentrant returns(address){
        uint newTokenRoyaltyId = tokenRoyaltyId;
        bytes32 salt = keccak256(abi.encodePacked(newTokenRoyaltyId, block.number, block.timestamp));
        address payable tokenRoyalty = payable(Clones.cloneDeterministic(tokenRoyaltySaleImplementation, salt));
        TokenRoyaltyDetails memory n_tokenRoyaltyDetails = TokenRoyaltyDetails(newTokenRoyaltyId, _askAmount, _returnPercentage, address(tokenRoyalty));
        royaltySaleAddress[creatorName][name] = tokenRoyalty;
        tokenRoyaltyDetailsMap[tokenRoyalty] = n_tokenRoyaltyDetails;
        tokenRoyaltyId++;
        TokenRoyaltySaleV3(tokenRoyalty).initialize(_askAmount, _returnPercentage, address(this), creator, creatorName, name, symbol);
        emit TokenRoyaltyCreated(_msgSender(), tokenRoyalty, newTokenRoyaltyId);
        return tokenRoyalty;
    }

    /// @notice the function is used to update the royalty percentage.
    /// @param _royaltyPercentage the amount in percentage the hub takes.
    /// @dev only hub admin can call this function 
    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()) , "Not Hub Admin");
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
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

    function getTokenRoyaltyAddress(string memory creatorName, string memory name) external view returns(address){
        return royaltySaleAddress[creatorName][name];
    }

    function getRoyaltySaleDetails(address _royaltySaleAddress) external view returns (TokenRoyaltyDetails memory) {
        return tokenRoyaltyDetailsMap[_royaltySaleAddress];
    }

    function getHubAddress() external view returns (address){
        return picardyHub;
    }

    function getLinkToken() external view returns(address){
        return linkToken;
    }
}

interface ITokenRoyaltySaleFactoryV3{
    function createTokenRoyalty(uint _askAmount, uint _returnPercentage, string memory creatorName, string memory name) external returns(address);
    function getRoyaltyDetails() external view returns (address, uint);
    function getHubAddress() external view returns (address);
    function getLinkToken() external view returns(address);
}