// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
interface INftRoyaltySaleFactory {

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

    function createNftRoyalty(Details memory details) external returns(address);
    
    function getRoyaltyDetails() external view returns (address, uint);
    
    function updateRoyaltyDetails(uint _royaltyPercentage) external ;
    
    function getRoyaltyUri(address _royaltyAddress) external view returns (string memory);
    
    function getLinkToken() external view returns(address);    
}