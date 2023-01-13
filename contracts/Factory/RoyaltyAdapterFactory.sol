/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../Automation/RoyaltyAdapter.sol";
import "../Automation/TokenRoyaltyAdapter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RoyaltyAdapterFactory is Context, ReentrancyGuard{

    event AdapterCreated(address indexed adapterAddress, uint indexed adapterId);

    address nftRoyaltyAdapterImplimentation;
    address tokenRoyaltyAdapterImplimentation;
    
    address public picardyHub;
    address public payMaster;
    address private linkToken;
    address private oracle;
    address private picardyReg;
    string jobId;

    uint256 adapterId = 1;

    struct AdapterDetails{
        address adapterAddress;
        uint256 adapterId;
    }

    mapping (address => AdapterDetails) public adapterDetails;
    mapping (uint => address) public adapterAddress;
    mapping (address => bool) public adapterExixt;

    modifier isHubAdmin{
        _isHubAdmin();
        _;
    }

    constructor (address _picardyHub, address _linkToken, address _oracle, string memory _jobId, address _nftRoyaltyAdapterImp, address _tokenRoyaltyAdapterImpl, address _payMaster){
        picardyHub = _picardyHub;
        payMaster = _payMaster;
        linkToken = _linkToken;
        oracle = _oracle;
        nftRoyaltyAdapterImplimentation = _nftRoyaltyAdapterImp;
        tokenRoyaltyAdapterImplimentation = _tokenRoyaltyAdapterImpl;
        jobId = _jobId;
    }

    function addPicardyReg(address _picardyReg) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "RoyaltyAdapterFactory: only hub admin");
        picardyReg = _picardyReg;
    }

    // Royalty Type 0 = NFT Royalty
    // Royalty Type 1 = Token Royalty
    function createAdapter(address _royaltySaleAddress, uint royaltyType, string memory _ticker) external nonReentrant returns(address){
        uint256 _adapterId = adapterId;
        
        if (royaltyType == 0){
        require(adapterExixt[_royaltySaleAddress] == false, "Adapter Already exist");
        bytes32 salt = keccak256(abi.encodePacked(_royaltySaleAddress, block.number, block.timestamp));
        address payable n_royaltyAdapter = payable(Clones.cloneDeterministic(nftRoyaltyAdapterImplimentation, salt));
        AdapterDetails memory n_adapterDetails = AdapterDetails({adapterAddress: n_royaltyAdapter, adapterId: _adapterId});
        adapterDetails[_royaltySaleAddress] = n_adapterDetails;
        adapterId++;
        adapterExixt[_royaltySaleAddress] = true;
        RoyaltyAdapter(n_royaltyAdapter).initilize(linkToken, oracle, jobId, _ticker, _royaltySaleAddress, msg.sender, payMaster, picardyReg);
        emit AdapterCreated(n_royaltyAdapter, _adapterId);
        return n_royaltyAdapter;
        } else if(royaltyType == 1){
        
        require(adapterExixt[_royaltySaleAddress] == false, "Adapter Already exist");
        bytes32 salt = keccak256(abi.encodePacked(_royaltySaleAddress, block.number, block.timestamp));
        address payable n_royaltyAdapter = payable(Clones.cloneDeterministic(tokenRoyaltyAdapterImplimentation, salt));
        AdapterDetails memory n_adapterDetails = AdapterDetails({adapterAddress:n_royaltyAdapter, adapterId: _adapterId});
        adapterDetails[_royaltySaleAddress] = n_adapterDetails;
        adapterId++;
        adapterExixt[_royaltySaleAddress] = true;
        TokenRoyaltyAdapter(n_royaltyAdapter).initilize(linkToken, oracle, jobId, _ticker, _royaltySaleAddress, msg.sender, payMaster, picardyReg);
        emit AdapterCreated(n_royaltyAdapter, _adapterId);
        return n_royaltyAdapter;
        }
        
    }

    function changeOracle(address _oracle) external isHubAdmin{
        oracle = _oracle;
    }

    function changeLinkToken(address _linkToken) external isHubAdmin{
        linkToken = _linkToken;
    }

    function changeJobId(string memory _jobId) external isHubAdmin{
        jobId = _jobId;
    }

    function _isHubAdmin() internal {
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()), "Not Hub Admin");
    }

    function getAdapterDetails(address _royaltySaleAddress) external view returns(AdapterDetails memory _adapterDetails){
        return adapterDetails[_royaltySaleAddress];
    }
}

interface IRoyaltyAdapterFactory {
    
    struct AdapterDetails{
        address adapterAddress;
        uint256 adapterId;
    }

    function changeOracle(address _oracle) external;

    function changeLinkToken(address _linkToken) external;

    function changeJobId(string memory _jobId) external;
  
    function getAdapterDetails(address _royaltySaleAddress) external view returns(AdapterDetails memory _adapterDetails);

    function createAdapter(address _royaltySaleAddress, uint royaltyType, string memory _ticker) external returns(address);
}
