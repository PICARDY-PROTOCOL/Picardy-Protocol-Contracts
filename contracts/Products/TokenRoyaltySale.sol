// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Tokens/CPToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IRoyaltyAdapter} from "../Chainlink/royaltyAdapter.sol";
import {ITokenRoyaltySaleFactory} from "../Factory/TokenRoyaltySaleFactory.sol";

contract TokenRoyaltySale is AutomationCompatibleInterface, ReentrancyGuard, Pausable {

    error OnlyKeeperRegistry();

    event RoyaltyBalanceUpdated(uint time);
    event Received(address indexed depositor, uint indexed amount);
    event UpkeepPerformed(uint indexed time);
    event AutomationStarted(bool indexed status);

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
    address private keeperRegistryAddress;
    address private royaltyAdapter;
    uint256 lastRoyaltyUpdate;
    uint256 updateInterval;
    bool automationStarted;
    bool initilized;

  
    mapping (address => uint) royaltyBalance;
    mapping (address => bool) isPoolMember;
    mapping (address => uint) memberSize;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyKeeperRegistry() {
        if (msg.sender != keeperRegistryAddress) {
            revert OnlyKeeperRegistry();
        }
        _;
    }

    function initilize(uint _royaltyPoolSize, uint _percentage, address _tokenRoyaltyFactory, address _creator, string memory _creatorsName, string memory _name) external {
        require(!initilized, "token Royalty: already initilized ");
        royalty.royaltyPoolSize = _royaltyPoolSize;
        royalty.percentage = _percentage;
        royalty.tokenRoyaltyFactory = _tokenRoyaltyFactory;
        royalty.creator = _creator;
        royalty.creatorsName = _creatorsName;
        royalty.name = _name;
        owner = _creator;
        _CPToken();
    }
    // constructor (uint _royaltyPoolSize, uint _percentage, address _tokenRoyaltyFactory, address _creator, string memory _creatorsName, string memory _name){
    //     royalty.royaltyPoolSize = _royaltyPoolSize;
    //     royalty.percentage = _percentage;
    //     royalty.tokenRoyaltyFactory = _tokenRoyaltyFactory;
    //     royalty.creator = _creator;
    //     royalty.creatorsName = _creatorsName;
    //     royalty.name = _name;
    //     transferOwnership(_creator);
    //     _CPToken();
    // }

    function start() external onlyOwner {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED);
        _start();
    }

        //call this to start automtion of the royalty contract, deposit link for automation
    function setupAutomation(address _regAddr, uint256 _updateInterval, address _royaltyAdapter) external onlyOwner {
        
        require (automationStarted == false, "startAutomation: automation started");
        keeperRegistryAddress = _regAddr;
        updateInterval = _updateInterval;
        royaltyAdapter = _royaltyAdapter;
        _startAutomation();
    }

    function _startAutomation() internal {
        require (automationStarted == false, "startAutomation: automation started");
        automationStarted = true;
        emit AutomationStarted(true);
    }

    function buyRoyalty() external payable {
        require(tokenRoyaltyState == TokenRoyaltyState.OPEN, "Sale closed");
        require(isPoolMember[msg.sender] == false);
        require(msg.value <=  royalty.royaltyPoolSize);
        royalty.royaltyPoolBalance += msg.value;
        _buyRoyalty(msg.value);
    }

    function _buyRoyalty(uint _amount) internal {
        isPoolMember[msg.sender] = true;
        royalty.royaltyPoolMembers.push(_msgSender());
        IERC20(royalty.royaltyCPToken).transfer( _msgSender(), _amount);
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
        upkeepNeeded = lastRoyaltyUpdate + updateInterval >= block.timestamp;
        performData = "";
        //performData = abi.encode(royalty.artistName, royalty.name);
        return (upkeepNeeded, performData);
    }

    //Performs upkeep
    function performUpkeep(
        bytes calldata
    ) external override onlyKeeperRegistry {
        //(string memory artisteName, string memory name) = abi.decode(performData, (string,string));
        // call the adapter contract and get the royalty value, and update holders
        IRoyaltyAdapter(royaltyAdapter).requestRoyaltyAmount();
        emit UpkeepPerformed(block.timestamp);
    }

    function updateRoyalty(uint amount) external {
        require (msg.sender == royaltyAdapter, "updateRoyalty: Un-auth");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        for(uint i = 0; i < royalty.royaltyPoolMembers.length; i++){
            address poolMember = royalty.royaltyPoolMembers[i];
            uint balance = IERC20(royalty.royaltyCPToken).balanceOf(poolMember);
            uint poolSize = (balance * 100) / royalty.royaltyPoolBalance;
            uint _amount = (poolSize * amount) / 100;
            royaltyBalance[poolMember] += _amount;
        }
        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyBalanceUpdated(block.timestamp);
    }

    function ownerUpdateRoyalty(uint amount) external onlyOwner {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        for(uint i = 0; i < royalty.royaltyPoolMembers.length; i++){
            address poolMember = royalty.royaltyPoolMembers[i];
            uint balance = IERC20(royalty.royaltyCPToken).balanceOf(poolMember);
            uint poolSize = (balance * 100) / royalty.royaltyPoolBalance;
            uint _amount = (poolSize * amount) / 100;
            royaltyBalance[poolMember] += _amount;
        }
        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyBalanceUpdated(block.timestamp);
    }

    function withdraw() external onlyOwner {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require(royalty.royaltyPoolBalance > 0, "Pool balance empty");
        (address royaltyAddress, uint royaltyPercentage) = ITokenRoyaltySaleFactory(royalty.tokenRoyaltyFactory).getRoyaltyDetails();
        uint balance = royalty.royaltyPoolBalance;
        uint txFee = (balance * royaltyPercentage) / 100;
        uint toWithdraw = balance - txFee;
        address _owner = payable(owner);
        (bool hs, ) = payable(royaltyAddress).call{value: txFee}("");
        (bool os, ) = _owner.call{value: toWithdraw}("");
        require(hs);
        require(os);
    }

    function withdrawRoyalty(uint _amount) external nonReentrant {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require(isPoolMember[msg.sender] == true);
        require(royaltyBalance[msg.sender] != 0);
        require(royaltyBalance[msg.sender] >= _amount);
        royaltyBalance[msg.sender] - _amount;
        (bool os, ) = payable(_msgSender()).call{value: _amount}("");
        require(os);
    }

    function changeRoyaltyState() external onlyOwner{
        require(tokenRoyaltyState == TokenRoyaltyState.OPEN, "royalty Closed");
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
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
        uint poolSize = (balance * 100) / royalty.royaltyPoolBalance;
        return poolSize;
    }

    function getRoyaltyBalance(address addr) external view returns(uint){
        return royaltyBalance[addr];
    }

    function getCreator() external view returns (address){
        return royalty.creator;
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


    function _CPToken() internal {
        CPToken newCpToken = new CPToken("Picardy Royalty Token");
        newCpToken.mint(royalty.royaltyPoolSize, address(this));
        royalty.royaltyCPToken = address(newCpToken);
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
    }

    function _start() internal {
        tokenRoyaltyState = TokenRoyaltyState.OPEN;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

interface IPicardyTokenRoyaltySale {
    
    /// @notice starts the token royalty sale
    function start() external ;

    /// @notice buys royalty
    function buyRoyalty(uint _amount) external payable;

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
   function updateRoyalty(uint amount) external;

   function getCreator() external view returns (address);

    /// @notice withdraws the royalty contract balance
    function withdraw() external;

    /// @notice withdraws the royalty balance
    function withdrawRoyalty(uint _amount) external;

}