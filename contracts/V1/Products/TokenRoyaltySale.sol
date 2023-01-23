// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../Tokens/CPToken.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {ITokenRoyaltyAdapter} from "../Automation/TokenRoyaltyAdapter.sol";
import {ITokenRoyaltySaleFactory} from "../Factory/TokenRoyaltySaleFactory.sol";

contract TokenRoyaltySale is AutomationCompatibleInterface, ReentrancyGuard, Pausable {

    event RoyaltyBalanceUpdated(uint indexed time, uint indexed amount);
    event Received(address indexed depositor, uint indexed amount);
    event UpkeepPerformed(uint indexed time);
    event AutomationStarted(bool indexed status);
    event RoyaltyWithdrawn(uint indexed amount, address indexed holder);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    enum TokenRoyaltyState{
        OPEN,
        CLOSED
    }

    TokenRoyaltyState tokenRoyaltyState;

    struct Royalty {
    uint royaltyPoolSize;
    uint percentage;
    uint royaltyPoolBalance;
    address royaltyCPToken;
    address tokenRoyaltyFactory;
    address creator;
    address[] royaltyPoolMembers;
    string creatorsName;
    string name;
    }

    Royalty royalty;
    
    address public owner;
    address private royaltyAdapter;
    uint256 lastRoyaltyUpdate;
    uint256 updateInterval;
    bool automationStarted;
    bool initilized;
    bool ownerWithdrawn;
    uint time = 1 minutes;

  
    mapping (address => uint) royaltyBalance;

    //holder => tokenAddress => royaltyBalance
    mapping (address => mapping(address => uint)) public ercRoyaltyBalance;
    mapping (address => bool) isPoolMember;
    mapping (address => uint) memberSize;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function initilize(uint _royaltyPoolSize, uint _percentage, address _tokenRoyaltyFactory, address _creator, string memory _creatorsName, string memory _name, address _owner) external {
        require(!initilized, "token Royalty: already initilized ");
        royalty.royaltyPoolSize = _royaltyPoolSize;
        royalty.percentage = _percentage;
        royalty.tokenRoyaltyFactory = _tokenRoyaltyFactory;
        royalty.creator = _creator;
        royalty.creatorsName = _creatorsName;
        royalty.name = _name;
        owner = _owner;
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
        initilized = true;
    }

    function start() external onlyOwner {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED);
        _start();
    }
    
    //This function is called by picardy royalty registrar, PS: royalty adapter contract needs LINK for automation to work
    function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external { 
        require(msg.sender == ITokenRoyaltyAdapter(_royaltyAdapter).getPicardyReg(), "setupAutomation: only picardy reg");
        require (automationStarted == false, "startAutomation: automation started");
        require(tokenRoyaltyState == TokenRoyaltyState.OPEN, "royalty Closed");
        updateInterval = _updateInterval * time;
        royaltyAdapter = _royaltyAdapter;
        lastRoyaltyUpdate = block.timestamp;
        automationStarted = true;
        emit AutomationStarted(true);
    }


    function toggleAutomation() external {
        require(msg.sender == ITokenRoyaltyAdapter(royaltyAdapter).getPicardyReg() || msg.sender == owner, "toggleAutomation: Un Auth");
        automationStarted = !automationStarted;
        emit AutomationStarted(false);
    }

    // TODO: add the pending balance function to be called by payMaster

    function buyRoyalty(address _holder) external payable whenNotPaused nonReentrant {
        require(tokenRoyaltyState == TokenRoyaltyState.OPEN, "Sale closed");
        require(msg.value <=  royalty.royaltyPoolSize);
        royalty.royaltyPoolBalance += msg.value;
        _buyRoyalty(msg.value, _holder);
    }

    function _buyRoyalty(uint _amount, address _holder) internal {
        if (isPoolMember[_holder] == false){
            royalty.royaltyPoolMembers.push(_holder);
            isPoolMember[_holder] = true;
        }
        (bool os) = IERC20(royalty.royaltyCPToken).transfer( _holder, _amount);
        require(os, "transfer failed");
        if(royalty.royaltyPoolSize == royalty.royaltyPoolBalance){
            tokenRoyaltyState = TokenRoyaltyState.CLOSED;
        }
    }

    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {   
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty Open");
        require(automationStarted == true, "automation not started");
        upkeepNeeded = (lastRoyaltyUpdate + updateInterval) >= block.timestamp;
        performData = "";
        //performData = abi.encode(royalty.artistName, royalty.name);
        return (upkeepNeeded, performData);
    }

    //Performs upkeep
    function performUpkeep(
        bytes calldata
    ) external override {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty Open");
        require(automationStarted == true, "automation not started");
        if((lastRoyaltyUpdate + updateInterval) >= block.timestamp){
            ITokenRoyaltyAdapter(royaltyAdapter).requestRoyaltyAmount();
            emit UpkeepPerformed(block.timestamp);
        }    
    }

     /**
        @dev This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20.    
    */
    function updateRoyalty(uint amount, address tokenAddress) external {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require (msg.sender == getUpdateRoyaltyCaller(), "updateRoyalty: Un-auth");
        address[] memory holders = CPToken(royalty.royaltyCPToken).getHolders();
        for(uint i = 0; i < holders.length; i++){
            address poolMember = holders[i];
            uint balance = IERC20(royalty.royaltyCPToken).balanceOf(poolMember);
            uint poolSize = (balance * 10000) / royalty.royaltyPoolBalance;
            uint _amount = (poolSize * amount) / 10000;
            ercRoyaltyBalance[poolMember][tokenAddress] += _amount;
        }
        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyBalanceUpdated(block.timestamp, amount);
    }

    function getUpdateRoyaltyCaller() private view returns (address) {
        if (automationStarted == true){
            return ITokenRoyaltyAdapter(royaltyAdapter).getPayMaster();
        } else {
            return owner;
        }   
    }



    function withdraw() external onlyOwner {
        require(ownerWithdrawn == false, "funds already withdrawn");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require(royalty.royaltyPoolBalance > 0, "Pool balance empty");
        (address royaltyAddress, uint royaltyPercentage) = ITokenRoyaltySaleFactory(royalty.tokenRoyaltyFactory).getRoyaltyDetails();
        uint balance = royalty.royaltyPoolBalance;
        uint royaltyPercentageToBips = royaltyPercentage * 100;
        uint txFee = (balance * royaltyPercentageToBips) / 10000;
        uint toWithdraw = balance - txFee;
        ownerWithdrawn = true;
        address _owner = payable(owner);
        (bool hs, ) = payable(royaltyAddress).call{value: txFee}("");
        (bool os, ) = _owner.call{value: toWithdraw}("");
        require(hs);
        require(os);
    }

    function withdrawRoyalty(uint _amount, address _holder) external nonReentrant {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require(address(this).balance >= _amount, "low balance");
        require(royaltyBalance[_holder] >= _amount, "Insufficient royalty balance");
        royaltyBalance[_holder] - _amount;
        (bool os, ) = payable(_holder).call{value: _amount}("");
        emit RoyaltyWithdrawn(_amount, _holder);
        require(os);
    }

    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external nonReentrant {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty still open");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "low balance");
        require(ercRoyaltyBalance[_holder][_tokenAddress] >= _amount, "Insufficient royalty balance");
        ercRoyaltyBalance[_holder][_tokenAddress] -= _amount;
        (bool os) = IERC20(_tokenAddress).transfer(_holder, _amount);
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);  
    }

    function changeRoyaltyState() external onlyOwner{
        require(tokenRoyaltyState == TokenRoyaltyState.OPEN, "royalty Closed");
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
    }

   function changeUpdateInterval(uint _updateInterval) external onlyOwner {
      updateInterval = _updateInterval * time;  
    }

    function changeAdapter(address _adapter) external {
        royaltyAdapter = _adapter;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    function getPoolMembers() external view returns (address[] memory){
        return royalty.royaltyPoolMembers;
    }

    function getPoolMemberCount() external view returns (uint){
        return royalty.royaltyPoolMembers.length;
    }

    function getPoolSize() external view returns(uint){
        return royalty.royaltyPoolSize;
    }

    function getPoolBalance() external view returns(uint){
        return royalty.royaltyPoolBalance;
    }

    function getMemberPoolSize(address addr) external view returns(uint){
        uint balance = IERC20(royalty.royaltyCPToken).balanceOf(addr);
        uint poolSize = (balance * 10000) / royalty.royaltyPoolBalance;
        return poolSize;
    }

    function getRoyatyTokenAddress() external view returns(address){
        return royalty.royaltyCPToken;
    }

    function getRoyaltyBalance(address addr) external view returns(uint){
        return royaltyBalance[addr];
    }

    function getERC20RoyaltyBalance(address addr, address tokenAddress) external view returns(uint){
        return ercRoyaltyBalance[addr][tokenAddress];
    }

    function getCreator() external view returns (address){
        return royalty.creator;
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function getRoyaltyPercentage() external view returns(uint){
        return royalty.percentage;
    }

    function getRoyaltyState() external view returns (uint){
        return uint(tokenRoyaltyState);
    }

    function getTokenDetails() external view returns(string memory, string memory) {
        return ( royalty.name, royalty.creatorsName);
    }

    function getTimeLeft() external view returns (uint256) {
        uint timePassed = block.timestamp - lastRoyaltyUpdate;
        uint nextUpdate = lastRoyaltyUpdate + updateInterval;
        uint timeLeft = nextUpdate - timePassed;
        return timeLeft;
    } 

    function checkAutomation() external view returns (bool) {
        return automationStarted;
    }

    function _start() internal {
        tokenRoyaltyState = TokenRoyaltyState.OPEN;
         _CPToken();
    }

    function _CPToken() internal {
        CPToken newCpToken = new CPToken("Picardy Royalty Token", address(this));
        royalty.royaltyCPToken = address(newCpToken);
        newCpToken.mint(royalty.royaltyPoolSize, address(this));
    }

    function _update(uint amount) internal {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        address[] memory holders = CPToken(royalty.royaltyCPToken).getHolders();
        for(uint i = 0; i < holders.length; i++){
            address poolMember = holders[i];
            uint balance = IERC20(royalty.royaltyCPToken).balanceOf(poolMember);
            require(balance != 0, "balance is zero");
            uint poolSize = (balance * 10000) / royalty.royaltyPoolBalance;
            uint _amount = (poolSize * amount) / 10000;
            royaltyBalance[poolMember] += _amount;
        }
        lastRoyaltyUpdate = block.timestamp;   
        emit RoyaltyBalanceUpdated(block.timestamp, msg.value);
    }

    receive() external payable {
        _update(msg.value);
    }
}

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

    function getOwner() external view returns(address);

    /// @notice withdraws the royalty contract balance
    function withdraw() external;

    /// @notice withdraws the royalty balance
    function withdrawRoyalty(uint _amount, address _holder) external;

    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external;

    function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external;

    function toggleAutomation() external ;

}