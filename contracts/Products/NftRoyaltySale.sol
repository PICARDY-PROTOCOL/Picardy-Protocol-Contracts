// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Tokens/PicardyNftBase.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {IRoyaltyAdapter} from "../Automation/RoyaltyAdapter.sol";
import {INftRoyaltySaleFactory} from "../Factory/NftRoyaltySaleFactory.sol";

contract NftRoyaltySale is ReentrancyGuard, Pausable, AutomationCompatibleInterface {


    error OnlyKeeperRegistry();

    event UpkeepPerformed(uint indexed time);
    event Received(address indexed sender, uint indexed amount);
    event AutomationStarted(bool indexed status);
    event RoyaltySold(uint indexed mintAmount, address indexed buyer);
    event RoyaltyUpdated(uint indexed royalty);
    event WithdrawSuccess(uint indexed time);
    event RoyaltyWithdrawn(uint indexed amount, address indexed holder);
    
    enum NftRoyaltyState {
        OPEN,
        CLOSED
    }

    NftRoyaltyState nftRoyaltyState;

    struct Royalty {
        uint maxMintAmount;
        uint maxSupply;
        uint cost;
        uint percentage;
        string artistName;
        string name;
        string initBaseURI;
        string symbol;
        address creator;
        address factoryAddress;
    }

    Royalty royalty;
    
    address public owner;
    address public nftRoyaltyAddress;
    address private royaltyAdapter;
    address private picardyReg;
    uint256 lastRoyaltyUpdate;
    uint256 updateInterval;
    bool automationStarted;
    bool initialized;
    bool ownerWithdrawn;
    uint time = 1 minutes;

    mapping (address => uint) nftBalance;
    mapping (address => uint) public royaltyBalance;
    mapping (address => uint[]) tokenIdMap;
    mapping (uint => bool) public isApproved;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    function initilize(uint _maxSupply, 
        uint _maxMintAmount, 
        uint _cost, 
        uint _percentage, 
        string memory _name,
        string memory _symbol, 
        string memory _initBaseURI, 
        string memory _artistName,
        address _creator,
        address _factroyAddress) public {
            require(!initialized, "already initialized");
            Royalty memory newRoyalty = Royalty(_maxMintAmount, _maxSupply, _cost, _percentage, _artistName, _name, _initBaseURI, _symbol, _creator, _factroyAddress);
            royalty = newRoyalty;
            owner = _creator;
            nftRoyaltyState = NftRoyaltyState.CLOSED;
            initialized = true;
        }

    function start() external onlyOwner {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED);
        _picardyNft();
        nftRoyaltyState = NftRoyaltyState.OPEN;
    }


    //call this to start automtion of the royalty contract, PS: contract needs LINK for automation to work
    function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external {
        require(msg.sender == IRoyaltyAdapter(_royaltyAdapter).getPicardyReg(), "setupAutomation: only picardy reg");
        require(automationStarted == false, "startAutomation: automation started");
        require(nftRoyaltyState == NftRoyaltyState.OPEN, "royalty sale closed");
        updateInterval = _updateInterval * time;
        royaltyAdapter = _royaltyAdapter;
        automationStarted = true;
        emit AutomationStarted(true);
    }

    function toggleAutomation() external onlyOwner{
        automationStarted = !automationStarted;
    }

    // Checks conditions for upkeep
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {   
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale open");
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
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale open");
        require(automationStarted == true, "automation not started");
        if((lastRoyaltyUpdate + updateInterval) >= block.timestamp){
            IRoyaltyAdapter(royaltyAdapter).requestRoyaltyAmount();
            emit UpkeepPerformed(block.timestamp);
        } 
    }

    function buyRoyalty(uint _mintAmount, address _holder) external payable {
        uint cost = royalty.cost;
        require(nftRoyaltyState == NftRoyaltyState.OPEN);
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        nftBalance[_holder] += _mintAmount;
        PicardyNftBase(nftRoyaltyAddress).buyRoyalty(_mintAmount, _holder);
        emit RoyaltySold(_mintAmount, _holder);
    }
    /**
        @dev This function is going to be modified with the use of an oracle and chanlink keeper for automation.    
    */
    function updateRoyalty(uint256 _amount) external {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        address payMaster = IRoyaltyAdapter(royaltyAdapter).getPayMaster();
        require (msg.sender == payMaster, "updateRoyalty: Un-auth");
        require (automationStarted == true, "automation not setup");
        uint saleCount = PicardyNftBase(nftRoyaltyAddress).getSaleCount();
        uint valuePerNft = _amount / saleCount;
        address[] memory holders = PicardyNftBase(nftRoyaltyAddress).getHolders();
        for(uint i; i < holders.length; i++){
            uint balance = valuePerNft * nftBalance[holders[i]];
            royaltyBalance[holders[i]] += balance;
        }
        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyUpdated(_amount);
    }
    // TODO: add the pending balance function to be called by payMaster

    function toggleRoyaltSale() external onlyOwner {
        if(nftRoyaltyState == NftRoyaltyState.OPEN){
            nftRoyaltyState = NftRoyaltyState.CLOSED;
        }else{
            nftRoyaltyState = NftRoyaltyState.OPEN;
        }
    }

    function pauseTokenBase() external onlyOwner{
        PicardyNftBase(nftRoyaltyAddress).pause();
    }

    function unPauseTokenBase() external onlyOwner {
        PicardyNftBase(nftRoyaltyAddress).unpause();
    }

    function getTimeLeft() external view returns (uint256) {
        uint timePassed = block.timestamp - lastRoyaltyUpdate;
        uint nextUpdate = lastRoyaltyUpdate + updateInterval;
        uint timeLeft = nextUpdate - timePassed;
        return timeLeft;
    }

    function getTokenDetails() external view returns(uint, uint, uint, string memory, string memory, string memory){  
        uint price = royalty.cost;
        uint maxSupply= royalty.maxSupply;
        uint percentage=royalty.percentage;
        string memory symbol =royalty.symbol;
        string memory name = royalty.name;
        string memory artisteName = royalty.artistName;

        return (price, maxSupply, percentage, symbol, name, artisteName);
    }

    function getCreator() external view returns(address){
        return royalty.creator;
    }

    function withdraw() external onlyOwner { 
        require(ownerWithdrawn == false, "funds already withdrawn");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        (address royaltyAddress, uint royaltyPercentage) = INftRoyaltySaleFactory(royalty.factoryAddress).getRoyaltyDetails();
         uint balance = address(this).balance;
         uint txFee = balance * royaltyPercentage / 100;
         uint toWithdraw = balance - txFee;
         ownerWithdrawn = true;
        (bool os, ) = payable(royaltyAddress).call{value: txFee}("");
        (bool hs, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(hs);
        require(os);
        emit WithdrawSuccess(block.timestamp);
    }

    function withdrawRoyalty(uint _amount, address _holder) external nonReentrant {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        require(address(this).balance >= _amount, "Insufficient funds");
        require(royaltyBalance[_holder] >= _amount, "Insufficient balance");
        royaltyBalance[_holder] -= _amount;
        (bool os, ) = payable(_holder).call{value: _amount}("");
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);
    }

    function withdrawRoyaltyERC(uint _amount, address _holder) external nonReentrant {
        require (automationStarted == true, "automation not started");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        address tokenAddress = IRoyaltyAdapter(royaltyAdapter).getTickerAddress();
        require(IERC20(tokenAddress).balanceOf(address(this)) >= _amount, "low balance");
        require(royaltyBalance[_holder] >= _amount, "Insufficient balance");
        royaltyBalance[_holder] -= _amount;
        (bool os) = IERC20(tokenAddress).transfer(_holder, _amount);
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Getter FUNCTIONS//

    function getTokensId(address _addr) external returns (uint[] memory){
        uint[] memory tokenIds = _getTokenIds(_addr);
        
        return tokenIds;
    }

    // INTERNAL FUNCTIONS//

 
    function _getTokenIds(address addr) internal returns(uint[] memory){
        uint[] storage tokenIds = tokenIdMap[addr];
        uint balance = IERC721Enumerable(nftRoyaltyAddress).balanceOf(addr);
        uint totalSupply = IERC721Enumerable(nftRoyaltyAddress).totalSupply();
        for (uint i; i< balance; i++){
            uint tokenId = IERC721Enumerable(nftRoyaltyAddress).tokenOfOwnerByIndex(msg.sender, i);
            tokenIds.push(tokenId);
        }
        return tokenIds;
    }

     function _picardyNft() internal {
        PicardyNftBase  newPicardyNft = new PicardyNftBase (royalty.maxSupply, royalty.maxMintAmount, royalty.percentage, royalty.name, royalty.symbol, royalty.initBaseURI, royalty.artistName, address(this), royalty.creator);
        nftRoyaltyAddress = address(newPicardyNft);
    }

    function _update(uint _amount) internal {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        uint saleCount = PicardyNftBase(nftRoyaltyAddress).getSaleCount();
        uint valuePerNft = _amount / saleCount;
        address[] memory holders = PicardyNftBase(nftRoyaltyAddress).getHolders();
        for(uint i; i < holders.length; i++){
            uint balance = valuePerNft * nftBalance[holders[i]];
            royaltyBalance[holders[i]] += balance;
        }

        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyUpdated(_amount);
    }

    receive() external payable {
        _update(msg.value);
    }

}

interface IPicardyNftRoyaltySale {

    /// @dev gets token ids of a specific address
    function getTokenIds(address _addr) external returns(uint[] memory);

    /// @dev gets token details of the caller
    function getTokenDetails() external returns(uint, uint, uint, string memory, string memory);

    function getCreator() external returns(address);
   
   /// @dev withdraws royalty balance of the caller
    function withdrawRoyalty(uint _amount) external;

    /// @dev updates royalty balance of token holders
    function updateRoyalty(uint256 _amount) external ;
    
    /// @dev buys royalty tokens
    function buyRoyalty(uint _mintAmount) external payable;

    function setupAutomation(address _regAddr, uint256 _updateInterval, address _royaltyAdapter) external;
    
    /// @dev pause the royalty sale contract
    function pause() external ;
    
    /// @dev unpauses the royalty sale contract
    function unpause() external ;
    
    /// @dev withdraws all eth sent to the royalty sale contract
    function withdraw() external ;
}