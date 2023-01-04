/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../Chainlink/royaltyAdapter.sol";
import "../Chainlink/tokenRoyaltyAdapter.sol";

contract RoyaltyAdapterFactory is Context{

    event AdapterCreated(address indexed adapterAddress, uint indexed adapterId);

    address nftRoyaltyAdapterImplimentation;
    address tokenRoyaltyAdapterImplimentation;
    
    address public picardyHub;
    address private linkToken;
    address oracle;
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

    constructor (address _picardyHub, address _linkToken, address _oracle, string memory _jobId, address _nftRoyaltyAdapterImp, address _tokenRoyaltyAdapterImpl){
        picardyHub = _picardyHub;
        linkToken = _linkToken;
        oracle = _oracle;
        nftRoyaltyAdapterImplimentation = _nftRoyaltyAdapterImp;
        tokenRoyaltyAdapterImplimentation = _tokenRoyaltyAdapterImpl;
        jobId = _jobId;
    }

    function createAdapter(address _royaltySaleAddress, uint royaltyType) external returns(address, uint256){
         uint256 _adapterId = adapterId;
        
        if (royaltyType == 0){
        require(adapterExixt[_royaltySaleAddress] == false, "Adapter Already exist");
        bytes32 salt = keccak256(abi.encodePacked(_royaltySaleAddress, block.number, block.timestamp));
        address payable n_royaltyAdapter = payable(Clones.cloneDeterministic(nftRoyaltyAdapterImplimentation, salt));
        RoyaltyAdapter(n_royaltyAdapter).initilize(linkToken, oracle, jobId, _royaltySaleAddress, msg.sender);
        AdapterDetails memory n_adapterDetails = AdapterDetails({adapterAddress: n_royaltyAdapter, adapterId: _adapterId});
        adapterDetails[_royaltySaleAddress] = n_adapterDetails;
        adapterId++;
        adapterExixt[_royaltySaleAddress] = true;
        emit AdapterCreated(n_royaltyAdapter, _adapterId);
        return(n_royaltyAdapter, _adapterId);
        } else if(royaltyType == 1){
        
        require(adapterExixt[_royaltySaleAddress] == false, "Adapter Already exist");
        bytes32 salt = keccak256(abi.encodePacked(_royaltySaleAddress, block.number, block.timestamp));
        address payable n_royaltyAdapter = payable(Clones.cloneDeterministic(tokenRoyaltyAdapterImplimentation, salt));
        TokenRoyaltyAdapter(n_royaltyAdapter).initilize(linkToken, oracle, jobId, _royaltySaleAddress, msg.sender);
        AdapterDetails memory n_adapterDetails = AdapterDetails({adapterAddress:n_royaltyAdapter, adapterId: _adapterId});
        adapterDetails[_royaltySaleAddress] = n_adapterDetails;
        adapterId++;
        adapterExixt[_royaltySaleAddress] = true;
        emit AdapterCreated(n_royaltyAdapter, _adapterId);
        return(n_royaltyAdapter, _adapterId);
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
