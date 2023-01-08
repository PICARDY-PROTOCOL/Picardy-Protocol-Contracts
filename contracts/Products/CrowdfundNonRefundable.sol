// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICrowdFundFactory} from "../Factory/CrowdfundFactory.sol";

contract CrowdfundNonRefundable is Ownable {

    using Address for address;

    event FundAdded(address indexed funder, uint indexed amount, uint indexed time);
    event FundWithdrawn(uint indexed time);

    enum FundState {
        OPEN,
        CLOSED
    }

    FundState fundState;

    struct FundDetails{  
    uint fundGoal;
    uint fundingTime;
    uint startTime;
    uint fundBalance;
    address creator;
    address fundFactory;
    address[] fundersLog;
    }

    FundDetails fundDetails;
 
    struct Funder {
        address addr;
        uint amount;
    }

    mapping (address => Funder) public funderMap;
    mapping (address => bool) public isFunder;

    constructor (address _creator, address _fundFactory, uint _fundGoal, uint _fundingTime){
        
        fundDetails.creator = _creator;
        fundDetails.fundFactory = _fundFactory;
        fundDetails.fundGoal = _fundGoal;
        fundDetails.fundingTime = _fundingTime * 1 days;
        fundDetails.startTime = block.timestamp;
        transferOwnership(_creator);
        fundState = FundState.OPEN;
    }

    /**
    
    */
    function fund(uint _amount) external payable {
        require(msg.value == _amount, "Amount sent does not match the amount requested");
        require(_amount > 0);
        require(fundState == FundState.OPEN, "Fund is closed");
        require(block.timestamp < fundDetails.startTime + fundDetails.fundingTime, "Fund has expired");
        _fund(_amount);
    }

    /**
    
    */
    function withdrawFund() external onlyOwner {
        require(block.timestamp > fundDetails.startTime + fundDetails.fundingTime);
        (address royaltyAddress, uint royaltyPercentage) = ICrowdFundFactory(fundDetails.fundFactory).getRoyaltyDetails();
        uint royalty = (royaltyPercentage/100) * address(this).balance;
        address _owner = payable(owner());
        (bool hs, ) = payable(royaltyAddress).call{value: royalty}("");
        (bool os, ) = _owner.call{value: address(this).balance}("");
        require(hs);
        require(os);

        emit FundWithdrawn(block.timestamp);
    }

  

    // GETTER FUNCTIONS//

    function getFundGoal() external view returns(uint ){
        return fundDetails.fundGoal;
    }

    function getCreator() external view returns(address){
        return fundDetails.creator;
    }

    function getFundBalance() external view returns(uint){
        return fundDetails.fundBalance;
    }

    function getFunders() external view returns(address[] memory){
        return fundDetails.fundersLog;
    }

    // INTERNAL FUNCTIONS //

    function _fund(uint _amount) internal {

        Funder memory newFunder = funderMap[msg.sender];
        newFunder = Funder(msg.sender, _amount);
    
        fundDetails.fundersLog.push(msg.sender);
        isFunder[msg.sender] = true;
        fundDetails.fundBalance += _amount;

        emit FundAdded(msg.sender, _amount, block.timestamp);

        if(block.timestamp > fundDetails.startTime + fundDetails.fundingTime){
            fundState = FundState.CLOSED;
        }
    }
}