// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

interface IPayMaster {
    function getRoyaltyReserve(address _adapter, string memory _ticker) external view returns (uint256);
    function getRoyaltyPending(address _adapter, string memory _ticker) external view returns (uint256);
    function getRoyaltyPaid(address _adapter, string memory _ticker) external view returns (uint256);
    function getTokenAddress(string memory _ticker) external view returns (address);
    function addRoyaltyReserve(address _adapter,string memory _ticker, uint256 _amount) external payable;
    function addRoyaltyData(address _adapter, address _royaltyAddress, uint royaltyType) external;
    function removeRoyaltyData(address _adapter, address _royaltyAddress) external;
    function sendPayment(address _adapter, string memory _ticker, uint256 _amount) external;
    function checkTickerExist(string memory _ticker) external view returns(bool);
}