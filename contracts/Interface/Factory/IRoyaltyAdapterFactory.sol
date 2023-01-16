// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;
interface IRoyaltyAdapterFactory {
    
    struct AdapterDetails{
        address adapterAddress;
        uint256 adapterId;
    }

    function changeOracle(address _oracle) external;

    function changeLinkToken(address _linkToken) external;

    function changeJobId(string memory _jobId) external;

    function getPayMaster() external view returns(address);
  
    function getAdapterDetails(address _royaltySaleAddress) external view returns(AdapterDetails memory _adapterDetails);

    function createAdapter(address _royaltySaleAddress, uint royaltyType, string memory _ticker) external returns(address);
}