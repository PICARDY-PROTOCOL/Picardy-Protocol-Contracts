// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../Tokens/CPTokenV3.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IRoyaltyAdapterV3} from "../AutomationV3/RoyaltyAdapterV3.sol";
import {ITokenRoyaltySaleFactoryV3} from "../FactoryV3/TokenRoyaltySaleFactoryV3.sol";

contract TokenRoyaltySaleV3 is ReentrancyGuard, Pausable {

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
    string symbol;
    }
    Royalty royalty;
  
    struct NodeDetails {
        address oracle;
        string jobId;
    }
    NodeDetails nodeDetails;

    address public owner;
    address private royaltyAdapter;
    uint256 lastRoyaltyUpdate;
    uint256 updateInterval;
    bool automationStarted;
    bool initilized;
    bool started;
    bool ownerWithdrawn;
    bool hasEnded;
    uint time = 1 minutes;
    uint royaltyType = 1;

  
    mapping (address => uint) royaltyBalance;

    //holder => tokenAddress => royaltyBalance
    mapping (address => mapping(address => uint)) public ercRoyaltyBalance;
    mapping (address => bool) isPoolMember;
    mapping (address => uint) memberSize;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function initialize(uint _royaltyPoolSize, uint _percentage, address _tokenRoyaltyFactory, address _creator, string memory _creatorsName, string memory _name, string calldata symbol) external {
        require(!initilized, "token Royalty: already initilized ");
        royalty.royaltyPoolSize = _royaltyPoolSize;
        royalty.percentage = _percentage;
        royalty.tokenRoyaltyFactory = _tokenRoyaltyFactory;
        royalty.creator = _creator;
        royalty.creatorsName = _creatorsName;
        royalty.name = _name;
        royalty.symbol = symbol;
        owner = _creator;
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
        initilized = true;
    }

    function start() external onlyOwner {
        require(!started, "already started");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED);
        _start();
        started = true;
    }
    
    /// @notice this function is called by Picardy Royalty Registrar when registering automation and sets up the automation
    /// @param _updateInterval update interval for the automation
    /// @param _royaltyAdapter address of Picardy Royalty Adapter
    /// @param _oracle address of the oracle
    /// @param _jobId job id for the oracle
    /// @dev This function is called by picardy royalty registrar, PS: royalty adapter contract needs LINK for automation to work
    function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string memory _jobId) external { 
        require(msg.sender == IRoyaltyAdapterV3(_royaltyAdapter).getPicardyReg(), "setupAutomation: only picardy reg");
        require (automationStarted == false, "startAutomation: automation started");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty still open");
        nodeDetails.oracle = _oracle;
        nodeDetails.jobId = _jobId;
        updateInterval = _updateInterval * time;
        royaltyAdapter = _royaltyAdapter;
        lastRoyaltyUpdate = block.timestamp;
        automationStarted = true;
        emit AutomationStarted(true);
    }

    /// @notice this function is called by the contract owner to pause automation
    /// @dev this function can only be called by the contract owner and picardy royalty registrar
    function toggleAutomation() external {
        require(msg.sender == IRoyaltyAdapterV3(royaltyAdapter).getPicardyReg() || msg.sender == owner, "toggleAutomation: Un Auth");
        automationStarted = !automationStarted;
        emit AutomationStarted(false);
    }
   
    /// @notice This function can be called by anyone and is a payable function to buy royalty token in ETH
    /// @param _holder address of the royalty token holder
    function buyRoyalty(address _holder) external payable whenNotPaused nonReentrant {
        require(hasEnded == false, "Sale Ended");
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
            hasEnded = true;
        }
    }

    /// @dev This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20.    
    /// @param amount amount of ERC20 tokens to be paid back to royalty holders
    /// @param tokenAddress address of the ERC20 token
    /// @dev this function can only be called by the contract owner or payMaster contract
    function updateRoyalty(uint amount, address tokenAddress) external {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require (msg.sender == getUpdateRoyaltyCaller(), "updateRoyalty: Un-auth");
        address[] memory holders = CPTokenV3(royalty.royaltyCPToken).getHolders();
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
            return IRoyaltyAdapterV3(royaltyAdapter).getPayMaster();
        } else {
            return owner;
        }   
    }

    /// @notice This function is used to withdraw the funds from the royalty sale contract and should only be called by the owner
    function withdraw() external onlyOwner {
        require(hasEnded == true, "sale not ended");
        require(ownerWithdrawn == false, "funds already withdrawn");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require(royalty.royaltyPoolBalance > 0, "Pool balance empty");
        (address royaltyAddress, uint royaltyPercentage) = ITokenRoyaltySaleFactoryV3(royalty.tokenRoyaltyFactory).getRoyaltyDetails();
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

    /// @notice This function is used to withdraw the royalty. It can only be called by the royalty token holder
    /// @param _amount amount of royalty token to be withdrawn
    /// @param _holder address of the royalty token holder
    function withdrawRoyalty(uint _amount, address _holder) external nonReentrant {
        require(hasEnded == true, "sale not ended");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require(address(this).balance >= _amount, "low balance");
        require(royaltyBalance[_holder] >= _amount, "Insufficient royalty balance");
        royaltyBalance[_holder] - _amount;
        (bool os, ) = payable(_holder).call{value: _amount}("");
        emit RoyaltyWithdrawn(_amount, _holder);
        require(os);
    }

    /// @notice This function is used to withdraw the royalty in ERC20. It can only be called by the royalty token holder
    /// @param _amount amount of royalty token to be withdrawn
    /// @param _holder address of the royalty token holder
    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external nonReentrant {
        require(hasEnded == true, "sale not ended");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty still open");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "low balance");
        require(ercRoyaltyBalance[_holder][_tokenAddress] >= _amount, "Insufficient royalty balance");
        ercRoyaltyBalance[_holder][_tokenAddress] -= _amount;
        (bool os) = IERC20(_tokenAddress).transfer(_holder, _amount);
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);  
    }

    /// @notice This function changes the state of the royalty sale and should only be called by the owner
    function changeRoyaltyState() external onlyOwner{
        require(hasEnded == false, "already ended");
        if(tokenRoyaltyState == TokenRoyaltyState.OPEN){
            tokenRoyaltyState = TokenRoyaltyState.CLOSED;
        } else {
            tokenRoyaltyState = TokenRoyaltyState.OPEN;
        }
    }

    /// @notice This function changes the state of the royalty sale to closed and should only be called by the owner, and can only be called once
    function endRoyaltySale() external onlyOwner {
        require(hasEnded == false, "endRoyaltySale: already ended");
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
        hasEnded = true;
    }

    /// @notice This function is uded to change the update interval of the royalty automation
    /// @param _updateInterval new update interval
   function changeUpdateInterval(uint _updateInterval) external onlyOwner {
      updateInterval = _updateInterval * time;  
    }

    /// @notice this function is used to transfer ownership of the sale contract to a new owner and should only be called by the owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    ///GETTERS
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

    function checkRoyaltyState() external view returns(bool){
        if(tokenRoyaltyState == TokenRoyaltyState.OPEN){
            return true;
        } else {
            return false;
        }
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

    function getLastRoyaltyUpdate() external view returns (uint) {
        return lastRoyaltyUpdate;
    }

    function _start() internal {
        tokenRoyaltyState = TokenRoyaltyState.OPEN;
         _CPToken(royalty.name, royalty.symbol);
    }

    function _CPToken(string memory name, string memory symbol) internal {
        CPTokenV3 newCpToken = new CPTokenV3(name, address(this), symbol);
        royalty.royaltyCPToken = address(newCpToken);
        newCpToken.mint(royalty.royaltyPoolSize, address(this));
    }

    /// @notice This function is used to update the royalty balance of royalty token holders
    /// @param amount amount of royalty to be distributed
    /// @dev this function is called in the receive fallback function.
    function _update(uint amount) internal {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        address[] memory holders = CPTokenV3(royalty.royaltyCPToken).getHolders();
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

interface IPicardyTokenRoyaltySaleV3 {
    
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

    function checkAutomation() external view returns (bool);

    /// @notice gets the royalty percentage
    function getRoyaltyPercentage() external view returns(uint);

    function getTokenDetails() external view returns(string memory, string memory);

    function checkRoyaltyState() external view returns(bool);

    function getLastRoyaltyUpdate() external view returns (uint);

    /// @notice updates the royalty balance
    function updateRoyalty(uint amount, address tokenAddress) external;

    function getCreator() external view returns (address);

    function getOwner() external view returns(address);

    /// @notice withdraws the royalty contract balance
    function withdraw() external;

    /// @notice withdraws the royalty balance
    function withdrawRoyalty(uint _amount, address _holder) external;

    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external;

    function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string memory _jobId) external;

    function toggleAutomation() external ;

}