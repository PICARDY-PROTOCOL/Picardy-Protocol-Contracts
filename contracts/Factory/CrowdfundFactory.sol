/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Products/CrowdfundNonRefundable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";

contract CrowdfundFactory is Context {

    event FundCreated (address indexed creator, address indexed fundAddress, uint indexed fundId);
    event RoyaltyDetailsUpdated(uint percentage, address royaltyAddress);
    struct Fund{
        uint fundId;
        uint fundingTime;
        uint fundGoal;
        address fundAddress;
    }

    struct RoyaltyDetails{
        uint royaltyPercentage;
        address royaltyAddress;
    }
    RoyaltyDetails royaltyDetails;

    mapping(uint => address) public fundIdMap;
    mapping(uint => Fund) public fundMap;
    address picardyHub;
    uint fundId = 1;

    constructor(address _picardyHub) {
        picardyHub = _picardyHub;
    }

    function getHubAddress() external view returns (address){
        return picardyHub;
    }

    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()), "Not Hub Admin");
        address royaltyAddress = IPicardyHub(picardyHub).getRoyaltyAddress();
        RoyaltyDetails memory newRoyaltyDetails = RoyaltyDetails(_royaltyPercentage, royaltyAddress);
        royaltyDetails = newRoyaltyDetails;
        emit RoyaltyDetailsUpdated(_royaltyPercentage, royaltyAddress);
    }

    function getRoyaltyDetails() external view returns (address, uint){
        address royaltyAddress = royaltyDetails.royaltyAddress;
        uint royaltyPercentage = royaltyDetails.royaltyPercentage;
        return(royaltyAddress, royaltyPercentage);
    }

    /**
        @dev Creates a craudfund contract
        @param _fundGoal The Requested amount from fund
        @param _fundingTime The time in days for which the fund is open
     */
    function createCrowdfund(uint _fundGoal, uint _fundingTime) external returns(address) {
        uint newFundId = fundId;
        CrowdfundNonRefundable croudfund = new CrowdfundNonRefundable(_msgSender(), address(this), _fundGoal, _fundingTime);
        Fund memory newFund = Fund(newFundId, _fundingTime, _fundGoal, address(croudfund));
        fundIdMap[newFundId] = address(croudfund);
        fundMap[newFundId] = newFund;
        fundId++;
        emit FundCreated(_msgSender(), address(croudfund), newFundId);
        return(address(croudfund));
    }

    function getFundAddress(uint _fundId) external view returns(address){
        return fundIdMap[_fundId];
    }
}

interface ICrowdFundFactory {
    function getHubAddress() external;
    function getRoyaltyDetails() external view returns (address, uint);
}