// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

interface IPicardyNftRoyaltySale {

    /// @dev gets token ids of a specific address
    function getTokenIds(address _addr) external returns(uint[] memory);

    /// @dev gets token details of the caller
    function getTokenDetails() external returns(uint, uint, uint, string memory, string memory);

    function getCreator() external returns(address);
   
   /// @dev withdraws royalty balance of the caller
    function withdrawRoyalty(uint _amount, address _holder) external;

    function withdrawRoyaltyERC(uint _amount, address _holder) external;

    /// @dev updates royalty balance of token holders
    function updateRoyalty(uint256 _amount, address tokenAddress) external ;
    
    /// @dev buys royalty tokens
    function buyRoyalty(uint _mintAmount, address _holder) external payable;

    function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external;

    function toggleAutomation() external;
    
    /// @dev pause the royalty sale contract
    function pause() external ;
    
    /// @dev unpauses the royalty sale contract
    function unpause() external ;
    
    /// @dev withdraws all eth sent to the royalty sale contract
    function withdraw() external ;
}