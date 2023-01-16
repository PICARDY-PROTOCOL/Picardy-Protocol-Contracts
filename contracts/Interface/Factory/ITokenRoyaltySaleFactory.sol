// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface ITokenRoyaltySaleFactory{
    function createTokenRoyalty(uint _askAmount, uint _returnPercentage, string memory creatorName, string memory name) external returns(address);
    function getRoyaltyDetails() external view returns (address, uint);
    function getHubAddress() external view returns (address);
    function getLinkToken() external view returns(address);
}