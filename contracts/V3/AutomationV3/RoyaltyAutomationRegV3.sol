// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/// @title Picardy RoyaltyAutomationRegistrarV2
/// @author Joshua Obigwe

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IPicardyNftRoyaltySaleV3} from "../ProductsV3/NftRoyaltySaleV3.sol";
import {IPicardyTokenRoyaltySaleV3} from "../ProductsV3/TokenRoyaltySaleV3.sol";
import {IPayMaster} from "../AutomationV3/PayMasterV3.sol";
import {IRoyaltyAdapterV3} from "./RoyaltyAdapterV3.sol";
import {IPicardyHub} from "../../PicardyHub.sol";

contract RoyaltyAutomationRegistrarV3 {

    /** @dev Picardy RoyaltyAutomationRegistrarV2 
        manages the royalty automation and inherits 
        chainlink KeeperRegistrarInterface.
     */

    event AutomationRegistered(address indexed royaltyAddress);
    event AutomationFunded(address indexed royaltyAddress, uint96 indexed amount);
    event AutomationCancled(address indexed royaltyAddress);
    event AutomationRestarted(address indexed royaltyAddress);
    event AutomationToggled(address indexed royaltyAddress);
    
    /// @notice details for a registered automation
    /// @param royaltyAddress the address of the royalty contract.
    /// @param adapterAddress the address of the royalty adapter contract.
    /// @param adminAddress the address of the admin of the automation. This can also be the address of the royalty owner
    /// @param upkeepId the upkeep id of the automation.
    /// @param royaltyType the type of royalty contract (0 = NFT, 1 = Token).
    /// @dev The struct is initilized in a mapping with the royalty address as the key.
    struct RegisteredDetails {
        address royaltyAddress;
        address adapterAddress;
        address adminAddress;
        uint royaltyType;
    }

    /// @notice details for registering a new automation
    /// @param ticker the ticker of that would be used to pay for the upkeep.
    /// @param jobId the job id of the job that would be used on the chainlink node (See Docs for more info).
    /// @param oracle the address of the Picardy oracle address (See Docs for more info).
    /// @param royaltyAddress the address of the royalty contract.
    /// @param adminAddress the address of the admin of the automation. This can also be the address of the royalty owner
    /// @param royaltyType the type of royalty contract (0 = NFT, 1 = Token).
    /// @param updateInterval the interval at which the automation would be updated.
    /// @param amount the amount of LINK to be sent to the upkeep contract.
    /// @dev The amount of link would be split and sent to chainlink for upkeep and picardy royalty adapter for oracle fees.
    struct RegistrationDetails {
        string ticker;
        string jobId;
        address oracle;
        address royaltyAddress;
        address adminAddress;
        uint royaltyType;
        uint updateInterval;
        uint96 amount;
    }
    
    address public link;
    address public adapter;
    address public picardyHub;
    address public payMaster;

    mapping (address => RegisteredDetails) public registeredDetails;
    mapping (address => bool) hasReg;

    IPayMaster i_payMaster;
    LinkTokenInterface i_link;

    constructor(
        address _link, //get from chainlink docs
        address _adapter,
        address _picardyHub,
        address _payMaster
    ) {
        picardyHub = _picardyHub;
        link = _link;
        payMaster = _payMaster;
        adapter = _adapter;
        i_payMaster = IPayMaster(_payMaster);
        i_link = LinkTokenInterface(_link);
        
    }

    /// @notice adds a new royalty adapter
    /// @param _adapterAddress address of the new royalty adapter
    /// @dev only callable by the PicardyHub admin
    function addRoyaltyAdapter(address _adapterAddress) external {
        require(_adapterAddress != address(0), "invalid adapter address");
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender), "Only PicardyHub can add royalty adapter");
        adapter = _adapterAddress;
    }

    /// @notice registers a new royalty contract for automation
    /// @param details struct containing all the details for the registration
    /// @dev only callable by the royalty contract owner see (RegistrationDetails struct above for more info).
    function register(RegistrationDetails memory details) external {
        require (details.updateInterval >= 1, "update interval too low");
        require (details.royaltyAddress != address(0), "invalid royalty address");
        require (details.adminAddress != address(0), "invalid admin address");
        require (details.oracle != address(0), "invalid oracle address");
        require(hasReg[details.royaltyAddress] == false, "already registered");
        require(i_link.balanceOf(msg.sender) >= details.amount, "Insufficient LINK for automation registration");
        require(i_payMaster.checkTickerExist(details.ticker), "Ticker not accepted");
        require (details.royaltyType == 0 || details.royaltyType == 1, "invalid Royalty type");

        if (details.royaltyType == 0){   
            IPicardyNftRoyaltySaleV3 royalty = IPicardyNftRoyaltySaleV3(details.royaltyAddress);
            require(msg.sender == royalty.getOwner(), "Only owner can register automation");   
            royalty.setupAutomationV2(details.updateInterval, adapter, details.oracle, details.jobId);
            i_link.transferFrom(msg.sender, adapter, details.amount);
            IRoyaltyAdapterV3(adapter).addValidSaleAddress(details.royaltyAddress, details.royaltyType, details.updateInterval, details.oracle, details.jobId, details.amount);
            i_payMaster.addRoyaltyData(
                adapter, 
                details.royaltyAddress, 
                details.royaltyType,
                details.ticker
            );
        }
        else if (details.royaltyType == 1){
            IPicardyTokenRoyaltySaleV3 royalty = IPicardyTokenRoyaltySaleV3(details.royaltyAddress);
            require(msg.sender == royalty.getOwner(), "Only owner can register automation");
            royalty.setupAutomationV2(details.updateInterval, adapter, details.oracle, details.jobId);
            IRoyaltyAdapterV3(adapter).addValidSaleAddress(details.royaltyAddress, details.royaltyType, details.updateInterval, details.oracle, details.jobId, details.amount);
            i_payMaster.addRoyaltyData(
                adapter, 
                details.royaltyAddress, 
                details.royaltyType,
                details.ticker
            );
        }
        RegisteredDetails memory i_registeredDetails = RegisteredDetails( details.royaltyAddress, adapter, details.adminAddress, details.royaltyType);
        registeredDetails[details.royaltyAddress] = i_registeredDetails;
        hasReg[details.royaltyAddress] = true;
        emit AutomationRegistered(details.royaltyAddress);   
    }

    /// @notice pauses automation can also be on the royalty contract
    /// @param _royaltyAddress address of the royalty contract
    function toggleAutomation(address _royaltyAddress) external {
        require(_royaltyAddress != address(0), "invalid royalty address");
        require(hasReg[_royaltyAddress] == true, "not registered");
        RegisteredDetails memory i_registeredDetails = registeredDetails[_royaltyAddress];
       
        require(i_registeredDetails.adminAddress == msg.sender, "not admin");
        
        if (i_registeredDetails.royaltyType == 0){
            IPicardyNftRoyaltySaleV3(_royaltyAddress).toggleAutomation();
        }
        else if (i_registeredDetails.royaltyType == 1){
            IPicardyTokenRoyaltySaleV3(_royaltyAddress).toggleAutomation();
        }
        
        emit AutomationToggled(_royaltyAddress);
    }

    /// @notice cancels automation
    /// @param _royaltyAddress address of the royalty contract
    function cancelAutomation(address _royaltyAddress) external {
        require(_royaltyAddress != address(0), "invalid royalty address");
        require(hasReg[_royaltyAddress] == true, "not registered");
        RegisteredDetails memory i_registeredDetails = registeredDetails[_royaltyAddress];
       
        require(i_registeredDetails.adminAddress == msg.sender, "not admin");
        if (i_registeredDetails.royaltyType == 0){
            IPicardyNftRoyaltySaleV3(_royaltyAddress).toggleAutomation();
        }
        else if (i_registeredDetails.royaltyType == 1){
            IPicardyTokenRoyaltySaleV3(_royaltyAddress).toggleAutomation();
        }
        i_payMaster.removeRoyaltyData(i_registeredDetails.adapterAddress, _royaltyAddress);
        hasReg[_royaltyAddress] = false;
        delete registeredDetails[_royaltyAddress];
        emit AutomationCancled(_royaltyAddress);
    }

    /// @notice updates automation configurations(link)
    /// @param _link address of the link token
    /// @dev can only be called by hub admin
    function updateAutomationConfig(address _link) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender), "not hub admin");
        require(_link != address(0), "link address cannot be address 0");
        //Initilize interface
        i_link = LinkTokenInterface(_link);
        //Initilize addresses
        link = _link;
       
    }

    /// @notice updates the paymaster address
    /// @param _payMaster address of the paymaster
    function updatePayMaster(address _payMaster) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender), "not hub admin");
        require(_payMaster != address(0), "payMaster address cannot be address 0");
        i_payMaster = IPayMaster(_payMaster);
        payMaster = _payMaster;
    }

    /// @notice gets royalty admin address
    function getAdminAddress(address _royaltyAddress) external view returns(address){
        return registeredDetails[_royaltyAddress].adminAddress;
    }

    /// @notice gets royalty adapter address
    function getRoyaltyAdapterAddress( address _royaltyAddress) external view returns(address){
        return registeredDetails[_royaltyAddress].adapterAddress;
    }

    /// @notice returns an struct of the registered details
    function getRegisteredDetails(address _royaltyAddress) external view returns(RegisteredDetails memory) {
        return registeredDetails[_royaltyAddress];
    }
}

interface IRoyaltyAutomationRegistrarV3 {
    struct RegistrationDetails {
        string ticker;
        string jobId;
        address oracle;
        address royaltyAddress;
        address adminAddress;
        uint royaltyType;
        uint updateInterval;
        uint96 amount;
    }

    struct RegisteredDetails {
        address royaltyAddress;
        address adapterAddress;
        address adminAddress;
        uint upkeepId;
        uint royaltyType;
        string ticker;
    }
    
    function register(RegistrationDetails memory details) external;

    function fundUpkeep(address royaltyAddress, uint96 amount) external;

    function toggleAutomation(address royaltyAddress) external;

    function addRoyaltyAdapter(address _adapterAddress) external;

    function fundAdapterBalance(uint96 _amount, address _royaltyAddress) external ;

    function cancleAutomation(address _royaltyAddress) external;

    function updateAutomationConfig(address _link) external;

    function updatePayMaster(address _payMaster) external;

    function getRoyaltyAdapterAddress( address _royaltyAddress) external view returns(address);

    function getAdminAddress(address _royaltyAddress) external view returns(address);

    function getRoyaltyTicker(address _royaltyAddress) external view returns(string memory);

    function getRegisteredDetails(address _royaltyAddress) external view returns(RegisteredDetails memory);
}