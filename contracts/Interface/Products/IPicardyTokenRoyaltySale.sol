// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
interface IPicardyTokenRoyaltySale {
    
    /// @notice starts the token royalty sale
    function start() external ;

    /// @notice buys royalty
    function buyRoyalty(uint _amount, address _holder) external payable;

    /// @notice gets the pool members
    function getPoolMembers() external view returns (address[] memory);

    /// @notice gets the pool member count
    function getPoolMemberCount() external view returns (uint);

    /// @notice gets the pool size
    function getPoolSize() external view returns(uint);

    /// @notice gets the pool balance
    function getPoolBalance() external view returns(uint);

    /// @notice gets the member pool size
    function getMemberPoolSize(address addr) external view returns(uint);

    /// @notice gets the royalty balance
    function getRoyaltyBalance(address addr) external view returns(uint);

    /// @notice gets the royalty percentage
    function getRoyaltyPercentage() external view returns(uint);

    function getTokenDetails() external view returns(string memory, string memory);

    /// @notice updates the royalty balance
    function updateRoyalty(uint amount, address tokenAddress) external;

    function getCreator() external view returns (address);

    /// @notice withdraws the royalty contract balance
    function withdraw() external;

    /// @notice withdraws the royalty balance
    function withdrawRoyalty(uint _amount, address _holder) external;

    function withdrawRoyalty2(uint _amount, address _holder) external;

    function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external;

    function toggleAutomation() external ;

}