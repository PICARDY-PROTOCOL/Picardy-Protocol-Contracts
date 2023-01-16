// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

interface IArtisteTokenFactory {
    function createArtisteToken(uint _totalAmount, string memory _name, string memory _symbol, uint _cost) external;
    function getRoyaltyDetails() external view returns (address, uint);
    function getHubAddress() external view returns (address);
}