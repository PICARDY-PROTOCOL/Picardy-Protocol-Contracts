// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

/// @title: NftRoyaltySaleFactoryV2
/// @author: Joshua Obigwe

import "../ProductsV3/NftRoyaltySaleV3.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../../PicardyHub.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftRoyaltySaleFactoryV3 is Context , ReentrancyGuard {

    address nftRoyaltySaleImplementation;

    event NftRoyaltySaleCreated (uint indexed royaltySaleId, address indexed creator, address indexed royaltySaleAddress);
    event RoyaltyDetailsUpdated(uint percentage, address royaltyAddress);
    
    /// @notice: Details for creating the NftRoyaltySale contract
    /// @param maxSupply: Maximum number of tokens that can be minted
    /// @param maxMintAmount: Maximum number of NFTs that can be minted in a single transaction
    /// @param cost: Cost of each token
    /// @param percentage: Percentage of split to be paid back to holders
    /// @param name: Name of the project / token
    /// @param symbol: Symbol of the project / token
    /// @param initBaseURI: Base URI for the token
    /// @param creatorName: Name of the creator
    /// @param creator: Address of the creator

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

    /// @notice: Details of the NftRoyaltySale contract
    /// @param royaltyId: Id of the royalty
    /// @param royaltyPercentage: Percentage of split to be paid back to holders
    /// @param royaltyName: Name of the Project / Token
    /// @param royaltyAddress: Address of the royalty

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

    address picardyHub;
    uint nftRoyaltyId = 1;
    address linkToken;
    constructor(address _picardyHub, address _linkToken, address _nftRoyaltySaleImpl) {
        picardyHub = _picardyHub;
        linkToken = _linkToken;
        nftRoyaltySaleImplementation = _nftRoyaltySaleImpl;
    }

    /// @notice Creates a new NftRoyaltySale contract
    /// @param details: Details of the NftRoyaltySale contract. (see struct Details for more info)
    /// @return  Address of the newly created NftRoyaltySale contract
    /// @dev  The NftRoyaltySale contract is created using the Clones library
    function createNftRoyalty(Details memory details) external nonReentrant returns(address){
        require(details.percentage <= 50, "Royalty percentage cannot be more than 50%");
        uint newRId = nftRoyaltyId;
        bytes32 salt = keccak256(abi.encodePacked(newRId, block.number, block.timestamp));
        address payable nftRoyalty = payable(Clones.cloneDeterministic(nftRoyaltySaleImplementation, salt));
        NftRoyaltyDetails memory newNftRoyaltyDetails = NftRoyaltyDetails(newRId, details.percentage, details.name, nftRoyalty);
        royaltySaleAddress[details.creatorName][details.name] = nftRoyalty;
        nftRoyaltyDetails[nftRoyalty] = newNftRoyaltyDetails;
        nftRoyaltyId++;
        NftRoyaltySaleV3(nftRoyalty).initialize(
            details.maxSupply, 
            details.maxMintAmount, 
            details.cost,  
            details.percentage , 
            details.name, 
            details.symbol, 
            details.initBaseURI, 
            details.creatorName, 
            details.creator, 
            address(this));
        emit NftRoyaltySaleCreated(newRId,_msgSender(), nftRoyalty);
        return nftRoyalty;
    }

    /// @notice Updates the royalty details
    /// @param _royaltyPercentage: percentage of transaction fee to be paid to the Picardy royalty address
    /// @dev Only the Picardy Hub Admin can call this function. Do not confuse this with the royalty percentage for the NftRoyaltySale contract 
    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()), "Not Hub Admin");
        address royaltyAddress = IPicardyHub(picardyHub).getRoyaltyAddress();
        RoyaltyDetails memory newRoyaltyDetails = RoyaltyDetails(_royaltyPercentage, royaltyAddress);
        royaltyDetails = newRoyaltyDetails;
        emit RoyaltyDetailsUpdated(_royaltyPercentage, royaltyAddress);
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

interface INftRoyaltySaleFactoryV3 {

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
    
    function getLinkToken() external view returns(address);    
}