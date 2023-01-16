// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
interface IRoyaltyAdapter{
    function requestRoyaltyAmount() external;
    function getRoyaltySaleAddress() external view returns (address);
    function getTickerAddress() external view returns(address);
    function updateRoyalty(uint _amount) external;
    function getPicardyReg() external view returns(address);
    function getPayMaster() external view returns(address);
}
