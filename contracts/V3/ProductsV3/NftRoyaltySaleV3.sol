// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

/// @title NftRoyaltySaleV2
/// @author Joshua Obigwe

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../Tokens/PicardyNftBase.sol";
import {IRoyaltyAdapterV3} from "../AutomationV3/RoyaltyAdapterV3.sol";
import {INftRoyaltySaleFactoryV2} from "../../V2/FactoryV2/NftRoyaltySaleFactoryV2.sol";

contract NftRoyaltySaleV3 is ReentrancyGuard, Pausable {

    event UpkeepPerformed(uint indexed time);
    event Received(address indexed sender, uint indexed amount);
    event AutomationStarted(bool indexed status);
    event RoyaltySold(uint indexed mintAmount, address indexed buyer);
    event RoyaltyUpdated(uint indexed royalty);
    event WithdrawSuccess(uint indexed time);
    event RoyaltyWithdrawn(uint indexed amount, address indexed holder);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    enum NftRoyaltyState {
        OPEN,
        CLOSED
    }

    NftRoyaltyState nftRoyaltyState;

    /// @notice Royalty struct
    /// @param maxMintAmount max amount of tokens that can be minted by an address
    /// @param maxSupply max amount of tokens that can be minted
    /// @param cost cost of each token
    /// @param percentage percentage of split to be paid back to holders
    /// @param creatorName name of the creator
    /// @param name name of the project / token
    /// @param initBaseURI base URI for the token
    /// @param symbol symbol of the project / token
    /// @param creator address of the creator
    /// @param factoryAddress address of the factory

    struct Royalty {
        uint maxMintAmount;
        uint maxSupply;
        uint cost;
        uint percentage;
        string creatorName;
        string name;
        string initBaseURI;
        string symbol;
        address creator;
        address factoryAddress;
    }

    Royalty royalty;

    struct NodeDetails {
        address oracle;
        string jobId;
    }
    NodeDetails nodeDetails;

    
    address owner;
    address public nftRoyaltyAddress;
    address private royaltyAdapter;
    address private picardyReg;
    uint256 lastRoyaltyUpdate;
    uint256 updateInterval;
    bool automationStarted;
    bool initialized;
    bool ownerWithdrawn;
    bool started;
    uint time = 1 minutes;
    uint royaltyType = 0;

    mapping (address => uint) nftBalance;
    mapping (address => uint) public royaltyBalance;

    //holder => tokenAddress => royaltyAmount
    mapping (address => mapping(address => uint)) public ercRoyaltyBalance;
    mapping (address => uint[]) tokenIdMap;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    function initialize(uint _maxSupply, 
        uint _maxMintAmount, 
        uint _cost, 
        uint _percentage, 
        string memory _name,
        string memory _symbol, 
        string memory _initBaseURI, 
        string memory _creatorName,
        address _creator,
        address _factroyAddress) public {
            require(!initialized, "already initialized");
            Royalty memory newRoyalty = Royalty(_maxMintAmount, _maxSupply, _cost, _percentage, _creatorName, _name, _initBaseURI, _symbol, _creator, _factroyAddress);
            royalty = newRoyalty;
            owner = _creator;
            nftRoyaltyState = NftRoyaltyState.CLOSED;
            initialized = true;
    }

    /// @notice this function is called by the contract owner to start the royalty sale
    /// @dev this function can only be called once and it cretes the NFT contract
    function start() external onlyOwner {
        require(started == false, "start: already started");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED);
        _picardyNft();
        nftRoyaltyState = NftRoyaltyState.OPEN;
        started = true;
    }

    
    /// @notice this function is called by Picardy Royalty Registrar when registering automation and sets up the automation
    /// @param _updateInterval update interval for the automation
    /// @param _royaltyAdapter address of Picardy Royalty Adapter
    /// @param _oracle address of the oracle
    /// @param _jobId job id for the oracle
    /// @dev //This function is called by picardy royalty registrar, PS: royalty adapter contract needs LINK for automation to work
    function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string memory _jobId) external {
        require(msg.sender == IRoyaltyAdapterV3(_royaltyAdapter).getPicardyReg() , "setupAutomation: only picardy reg");
        require(automationStarted == false, "startAutomation: automation started");
        require(nftRoyaltyState == NftRoyaltyState.OPEN, "royalty sale closed");
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
        require(msg.sender == IRoyaltyAdapterV3(royaltyAdapter).getPicardyReg() ||msg.sender == owner, "toggleAutomation: Un Auth");
        automationStarted = !automationStarted;
        emit AutomationStarted(false);
    }

    /// @notice This function can be called by anyone and is a payable function to buy royalty token in ETH
    /// @param _mintAmount amount of royalty token to be minted
    /// @param _holder address of the royalty token holder
    function buyRoyalty(uint _mintAmount, address _holder) external payable whenNotPaused nonReentrant{
        uint cost = royalty.cost;
        require(nftRoyaltyState == NftRoyaltyState.OPEN);
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        nftBalance[_holder] += _mintAmount;
        PicardyNftBase(nftRoyaltyAddress).buyRoyalty(_mintAmount, _holder);
        emit RoyaltySold(_mintAmount, _holder); 
    }

    
    /// @dev This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20.    
    /// @param _amount amount of ERC20 tokens to be paid back to royalty holders
    /// @param tokenAddress address of the ERC20 token
    /// @dev this function can only be called by the contract owner or payMaster contract
    function updateRoyalty(uint256 _amount, address tokenAddress) external {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        require (msg.sender == getUpdateRoyaltyCaller(), "updateRoyalty: Un-auth");
        uint saleCount = PicardyNftBase(nftRoyaltyAddress).getSaleCount();
        uint valuePerNft = _amount / saleCount;
        address[] memory holders = PicardyNftBase(nftRoyaltyAddress).getHolders();
        for(uint i; i < holders.length; i++){
            uint balance = valuePerNft * nftBalance[holders[i]];
            ercRoyaltyBalance[holders[i]][tokenAddress] += balance;
        }
        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyUpdated(_amount);
    }

    /// @notice helper function that makes sure the caller is the owner or payMaster contract
    function getUpdateRoyaltyCaller() internal view returns (address) {
        if (automationStarted == true){
            return IRoyaltyAdapterV3(royaltyAdapter).getPayMaster();
        } else {
            return owner;
        }   
    }

    /// @notice This function changes the state of the royalty sale and should only be called by the owner
    function toggleRoyaltySale() external onlyOwner {
        if(nftRoyaltyState == NftRoyaltyState.OPEN){
            nftRoyaltyState = NftRoyaltyState.CLOSED;
        }else{
            nftRoyaltyState = NftRoyaltyState.OPEN;
        }
    }

    /// @notice his function is used to pause the ERC721 token base contract
    /// @dev this function can only be called by the contract owner
    function pauseTokenBase() external onlyOwner{
        PicardyNftBase(nftRoyaltyAddress).pause();
    }

    /// @notice his function is used to unPause the ERC721 token base contract
    /// @dev this function can only be called by the contract owner
    function unPauseTokenBase() external onlyOwner {
        PicardyNftBase(nftRoyaltyAddress).unpause();
    }

    function getTimeLeft() external view returns (uint256) {
        uint timePassed = block.timestamp - lastRoyaltyUpdate;
        uint nextUpdate = lastRoyaltyUpdate + updateInterval;
        uint timeLeft = nextUpdate - timePassed;
        return timeLeft;
    }

    function checkNftRoyaltyState() external view returns(bool){
        if(nftRoyaltyState == NftRoyaltyState.OPEN){
            return true;
        }else{
            return false;
        }
    }

    /// @notice This function is used to withdraw the funds from the royalty sale contract and should only be called by the owner
    function withdraw() external onlyOwner { 
        require(ownerWithdrawn == false, "funds already withdrawn");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        (address royaltyAddress, uint royaltyPercentage) = INftRoyaltySaleFactoryV2(royalty.factoryAddress).getRoyaltyDetails();
         uint balance = address(this).balance;
         uint royaltyPercentageTobips = royaltyPercentage * 100;
         uint txFee = (balance * royaltyPercentageTobips) / 10000;
         uint toWithdraw = balance - txFee;
         ownerWithdrawn = true;
        (bool os, ) = payable(royaltyAddress).call{value: txFee}("");
        (bool hs, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(hs);
        require(os);
        emit WithdrawSuccess(block.timestamp);
    }

    /// @notice This function is used to withdraw the royalty. It can only be called by the royalty token holder
    /// @param _amount amount of royalty token to be withdrawn
    /// @param _holder address of the royalty token holder
    function withdrawRoyalty(uint _amount, address _holder) external nonReentrant {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        require(address(this).balance >= _amount, "Insufficient funds");
        require(royaltyBalance[_holder] >= _amount, "Insufficient balance");
        royaltyBalance[_holder] -= _amount;
        (bool os, ) = payable(_holder).call{value: _amount}("");
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);
    }

    /// @notice This function is used to withdraw the royalty in ERC20. It can only be called by the royalty token holder
    /// @param _amount amount of royalty token to be withdrawn
    /// @param _holder address of the royalty token holder
    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external nonReentrant {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open"); 
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "low balance");
        require(ercRoyaltyBalance[_holder][_tokenAddress] >= _amount, "Insufficient royalty balance");
        ercRoyaltyBalance[_holder][_tokenAddress] -= _amount;
        (bool os) = IERC20(_tokenAddress).transfer(_holder, _amount);
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);
    }
    
    /// @notice This function is uded to change the update interval of the royalty automation
    /// @param _updateInterval new update interval
    function changeUpdateInterval(uint _updateInterval) external onlyOwner {
      updateInterval = _updateInterval * time;  
    }

    /// @notice This function is used to pause the royalty sale contract and should only be called by the owner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice This function is used to unpause the royalty sale contract and should only be called by the owner
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice this function is used to transfer ownership of the sale contract to a new owner and should only be called by the owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    /// @notice This function is used to change the oracle address and jobId of the chainlink node for custom job id
    /// @param _oracle new oracle address
    /// @param _jobId new jobId
    /// @dev this function can only be called by the contract owner. (See docs for custom automation)
    function updateNodeDetails(address _oracle, string calldata _jobId) external onlyOwner{
        nodeDetails.oracle = _oracle;
        nodeDetails.jobId = _jobId;
    }

    //Getter FUNCTIONS//

    function getTokensId(address _addr) external returns (uint[] memory){
        uint[] memory tokenIds = _getTokenIds(_addr);
        
        return tokenIds;
    }

    function getERC20RoyaltyBalance(address _holder, address _tokenAddress) external view returns(uint){
        return ercRoyaltyBalance[_holder][_tokenAddress];
    }

    function getTokenDetails() external view returns(uint, uint, uint, string memory, string memory, string memory){  
        uint price = royalty.cost;
        uint maxSupply= royalty.maxSupply;
        uint percentage=royalty.percentage;
        string memory symbol =royalty.symbol;
        string memory name = royalty.name;
        string memory creatorName = royalty.creatorName;

        return (price, maxSupply, percentage, symbol, name, creatorName);
    }

    function getCreator() external view returns(address){
        return royalty.creator;
    }

    function getRoyaltyTokenAddress() external view returns(address){
        return nftRoyaltyAddress;
    }

    function getOwner() external view returns(address){
        return owner;
    }

   function getRoyaltyPercentage() external view returns(uint){
        return royalty.percentage;
    }

    function getLastRoyaltyUpdate() external view returns(uint){
        return lastRoyaltyUpdate;
    }

    // INTERNAL FUNCTIONS//

 
    function _getTokenIds(address addr) internal returns(uint[] memory){
        uint[] storage tokenIds = tokenIdMap[addr];
        uint balance = IERC721Enumerable(nftRoyaltyAddress).balanceOf(addr);
        for (uint i; i< balance; i++){
            uint tokenId = IERC721Enumerable(nftRoyaltyAddress).tokenOfOwnerByIndex(msg.sender, i);
            tokenIds.push(tokenId);
        }
        return tokenIds;
    }

    function checkAutomation() external view returns(bool){
        return automationStarted;
    }

     function _picardyNft() internal {
        PicardyNftBase  newPicardyNft = new PicardyNftBase (royalty.maxSupply, royalty.maxMintAmount, royalty.percentage, royalty.name, royalty.symbol, royalty.initBaseURI, royalty.creatorName, address(this), royalty.creator);
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

interface IPicardyNftRoyaltySaleV3 {

    /// starts royalty sale
    function start() external;
    
    /// @dev gets token ids of a specific address
    function getTokenIds(address _addr) external returns(uint[] memory);

    /// @dev gets token details of the caller
    function getTokenDetails() external returns(uint, uint, uint, string memory, string memory);

    function getCreator() external returns(address);
   
   /// @dev withdraws royalty balance of the caller
    function withdrawRoyalty(uint _amount, address _holder) external;

    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external;

    function getRoyaltyTokenAddress() external view returns(address);

    /// @dev updates royalty balance of token holders
    function updateRoyalty(uint256 _amount, address tokenAddress) external ;

    function getTokensId(address _addr) external returns (uint[] memory);
    /// @dev buys royalty tokens
    function buyRoyalty(uint _mintAmount, address _holder) external payable;

    function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string memory _jobId) external;

    function toggleAutomation() external;

    function toggleRoyaltySale() external;

    function changeUpdateInterval(uint _updateInterval) external;

    function checkRoyaltyState() external view returns(bool);

    function getLastRoyaltyUpdate() external view returns(uint);

    function getERC20RoyaltyBalance(address _holder, address _tokenAddress) external view returns(uint);

    function getRoyaltyPercentage() external view returns(uint);

    function checkAutomation() external view returns (bool);

    function updateNodeDetails(address _oracle, string calldata _jobId) external;

    function getOwner() external view returns(address);
    /// @dev pause the royalty sale contract
    function pause() external ;
    
    /// @dev unpauses the royalty sale contract
    function unpause() external ;
    
    /// @dev withdraws all eth sent to the royalty sale contract
    function withdraw() external ;
}