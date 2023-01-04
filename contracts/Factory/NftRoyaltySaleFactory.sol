/**
    @author Blok_Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/NftRoyaltySale.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";

contract NftRoyaltySaleFactory is Context {

    event NftRoyaltySaleCreated (uint indexed royaltySaleId, address indexed creator, address indexed royaltySaleAddress);
     event RoyaltyDetailsUpdated(uint percentage, address royaltyAddress);
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

    constructor(address _picardyHub, address _linkToken) {
        picardyHub = _picardyHub;
        linkToken = _linkToken;
    }

    /**
        @dev Creates an ERC721 royalty sale contract
        @param _maxSupply The maximum supply of the Royalty Token
        @param _maxMintAmount The maximum amount of token a user can buy 
        @param _cost The price of each token
        @param _percentage The percentage of royalty to be sold
        @param _name The name of the royalty
        @param _symbol The token symbol
        @param _initBaseURI Image and metadata URI
     */
    function createNftRoyalty(
        uint _maxSupply, 
        uint _maxMintAmount, 
        uint _cost, 
        uint _percentage,
        string calldata _name, 
        string calldata _symbol, 
        string calldata _initBaseURI,
        string calldata _artisteName
        ) external returns(address){
        require(_percentage <= 50, "Royalty percentage cannot be more than 50%");
        uint newRId = nftRoyaltyId;
        NftRoyaltySale nftRoyalty = new NftRoyaltySale(_maxSupply, _maxMintAmount, _cost,  _percentage ,_name, _symbol, _initBaseURI, _artisteName, _msgSender(), address(this));
        NftRoyaltyDetails memory newNftRoyaltyDetails = NftRoyaltyDetails(newRId, _percentage, _name, address(nftRoyalty));
        royaltySaleAddress[_artisteName][_name] = address(nftRoyalty);
        nftRoyaltyDetails[address(nftRoyalty)] = newNftRoyaltyDetails;
        nftRoyaltyId++;
        emit NftRoyaltySaleCreated(newRId,_msgSender(), address(nftRoyalty));
        return (address(nftRoyalty));
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

    function getNftRoyaltySaleAddress(string memory _artisteName, string memory _name) external view returns (address){
        return royaltySaleAddress[_artisteName][_name];
    }
}

interface INftRoyaltySaleFactory {
    function getRoyaltyDetails() external view returns (address, uint);
    function updateRoyaltyDetails(uint _royaltyPercentage) external ;
    function getRoyaltyUri(address _royaltyAddress) external view returns (string memory);
    function getLinkToken() external view returns(address);    
}