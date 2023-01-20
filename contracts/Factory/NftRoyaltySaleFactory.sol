/**
    @author Blok_Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/NftRoyaltySale.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftRoyaltySaleFactory is Context , ReentrancyGuard {

    address nftRoyaltySaleImplementation;

    event NftRoyaltySaleCreated (uint indexed royaltySaleId, address indexed creator, address indexed royaltySaleAddress);
     event RoyaltyDetailsUpdated(uint percentage, address royaltyAddress);
    
    struct Details {
        uint maxSupply; 
        uint maxMintAmount; 
        uint cost; 
        uint percentage;
        string name;
        string symbol; 
        string initBaseURI;
        string creatorName;
        address creator;
    }

    struct NftRoyaltyDetails {
        uint royaltyId;
        uint royaltyPercentage;
        string royaltyName;
        address royaltyAddress;
    }


    struct RoyaltyDetails{
        uint royaltyPercentage;
        address royaltyAddress;
    }
    RoyaltyDetails royaltyDetails;

    mapping(address => NftRoyaltyDetails) public nftRoyaltyDetails;
    mapping(string => mapping (string => address)) public royaltySaleAddress;
    mapping(address => string) private royaltyUrl;

    address picardyHub;
    uint nftRoyaltyId = 1;
    address linkToken;

    constructor(address _picardyHub, address _linkToken, address _nftRoyaltySaleImpl) {
        picardyHub = _picardyHub;
        linkToken = _linkToken;
        nftRoyaltySaleImplementation = _nftRoyaltySaleImpl;
    }

    function createNftRoyalty(Details memory details) external nonReentrant returns(address){
        require(details.percentage <= 50, "Royalty percentage cannot be more than 50%");
        uint newRId = nftRoyaltyId;
        bytes32 salt = keccak256(abi.encodePacked(newRId, block.number, block.timestamp));
        address payable nftRoyalty = payable(Clones.cloneDeterministic(nftRoyaltySaleImplementation, salt));
        NftRoyaltyDetails memory newNftRoyaltyDetails = NftRoyaltyDetails(newRId, details.percentage, details.name, nftRoyalty);
        royaltySaleAddress[details.creatorName][details.name] = nftRoyalty;
        nftRoyaltyDetails[nftRoyalty] = newNftRoyaltyDetails;
        nftRoyaltyId++;
        NftRoyaltySale(nftRoyalty).initilize(details.maxSupply, details.maxMintAmount, details.cost,  details.percentage , details.name, details.symbol, details.initBaseURI, details.creatorName, details.creator, address(this), _msgSender());
        emit NftRoyaltySaleCreated(newRId,_msgSender(), nftRoyalty);
        return (nftRoyalty);
    }

    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()), "Not Hub Admin");
        address royaltyAddress = IPicardyHub(picardyHub).getRoyaltyAddress();
        RoyaltyDetails memory newRoyaltyDetails = RoyaltyDetails(_royaltyPercentage, royaltyAddress);
        royaltyDetails = newRoyaltyDetails;
        emit RoyaltyDetailsUpdated(_royaltyPercentage, royaltyAddress);
    }

    //Add royalty uri to factory for external api call, This function can only be called by picardyHub admin
    function addRoyaltyUri(address _royaltyAddress, string memory _royaltyUri) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()), "Not Hub Admin");
        royaltyUrl[_royaltyAddress]  = _royaltyUri;
    }

    function getRoyaltyUri(address _royaltyAddress) external view returns (string memory){
        return royaltyUrl[_royaltyAddress];
    }

    function getLinkToken() external view returns(address){
        return linkToken;
    }

    function getRoyaltyDetails() external view returns (address, uint){
        address royaltyAddress = royaltyDetails.royaltyAddress;
        uint royaltyPercentage = royaltyDetails.royaltyPercentage;
        return(royaltyAddress, royaltyPercentage);
    }

    function getHubAddress() external view returns (address){
        return picardyHub;
    }

    function getNftRoyaltySaleAddress(string memory _creatorName, string memory _name) external view returns (address){
        return royaltySaleAddress[_creatorName][_name];
    }
}

interface INftRoyaltySaleFactory {

    struct Details {
        uint maxSupply; 
        uint maxMintAmount; 
        uint cost; 
        uint percentage;
        string name;
        string symbol; 
        string initBaseURI;
        string creatorName;
        address creator;
    }

    function createNftRoyalty(Details memory details) external returns(address);
    
    function getRoyaltyDetails() external view returns (address, uint);
    
    function updateRoyaltyDetails(uint _royaltyPercentage) external ;
    
    function getRoyaltyUri(address _royaltyAddress) external view returns (string memory);
    
    function getLinkToken() external view returns(address);    
}