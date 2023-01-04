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

contract NftRoyaltySaleFactory is Context {

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
        string artisteName;
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

    function createNftRoyalty(Details memory details) external returns(address){
        require(details.percentage <= 50, "Royalty percentage cannot be more than 50%");
        uint newRId = nftRoyaltyId;
        bytes32 salt = keccak256(abi.encodePacked(newRId, block.number, block.timestamp));
        address nftRoyalty = payable(Clones.cloneDeterministic(nftRoyaltySaleImplementation, salt));
        bytes memory data = abi.encode(details.maxSupply, details.maxMintAmount, details.cost,  details.percentage , details.name, details.symbol, details.initBaseURI, details.artisteName, _msgSender(), address(this));
        initilizeRoyaltySale(data);
        NftRoyaltyDetails memory newNftRoyaltyDetails = NftRoyaltyDetails(newRId, details.percentage, details.name, nftRoyalty);
        royaltySaleAddress[details.artisteName][details.name] = nftRoyalty;
        nftRoyaltyDetails[nftRoyalty] = newNftRoyaltyDetails;
        nftRoyaltyId++;
        emit NftRoyaltySaleCreated(newRId,_msgSender(), nftRoyalty);
        return (nftRoyalty);
    }

    function initilizeRoyaltySale(bytes memory data) internal {
        (uint _maxSupply, uint _maxMintAmount, uint _cost, uint _percentage, string memory _name, string memory _symbol, string memory _initBaseURI, string memory _artisteName, address _creator, address _factory, address payable _nftRoyaltySale) = abi.decode(data, (uint, uint, uint, uint, string, string, string, string, address, address, address));
        NftRoyaltySale(_nftRoyaltySale).initialize(_maxSupply, _maxMintAmount, _cost,  _percentage ,_name, _symbol, _initBaseURI, _artisteName, _creator, _factory);
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