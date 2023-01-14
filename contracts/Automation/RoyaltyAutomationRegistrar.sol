// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IPicardyNftRoyaltySale} from "../Products/NftRoyaltySale.sol";
import {IPicardyTokenRoyaltySale} from "../Products/TokenRoyaltySale.sol";
import {IPayMaster} from "../Automation/PayMaster.sol";
import {IRoyaltyAdapterFactory} from "../Factory/RoyaltyAdapterFactory.sol";
import {IPicardyHub} from "../PicardyHub.sol";

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

contract RoyaltyAutomationRegistrar {

    event AutomationRegistered(address indexed royaltyAddress);
    struct RegisteredDetails {
        address royaltyAddress;
        address adapterAddress;
        address adminAddress;
        uint upkeepId;
    }

    struct RegistrationDetails {
        string name;
        string ticker;
        string email;
        address royaltyAddress;
        address adminAddress;
        uint royaltyType;
        uint updateInterval;
        uint32 gasLimit;
        uint96 amount;
    }

    struct PayloadDetails {
        string name;
        bytes encryptedEmail;
        address royaltyAddress;
        uint32 gasLimit;
        address adminAddress; 
        bytes checkData;
        uint96 amount; 
        uint8 source; 
    }
    
    address public link;
    address public registry;
    address public registrar;
    address public adapterFactory;
    address public picardyHub;
    address public payMaster;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    mapping (address => RegisteredDetails) public registeredDetails;

    constructor(
        address _link, //get fromchainlink docs
        address _registrar, //get from chainlink docs
        address _registry, //get from chainlink docs
        address _adapterFactory,
        address _picardyHub,
        address _payMaster
    ) {
        link = _link;
        registrar = _registrar;
        registry = _registry;
        picardyHub = _picardyHub;
        payMaster = _payMaster;
        adapterFactory = _adapterFactory;
    }

    function register(RegistrationDetails memory details) external {
        
        bytes memory encryptedEmail = abi.encode(details.email);
        IPayMaster i_payMaster = IPayMaster(payMaster);
        LinkTokenInterface i_link = LinkTokenInterface(link);
        AutomationRegistryInterface i_registry = AutomationRegistryInterface(registry);
        RegisteredDetails memory i_registeredDetails = registeredDetails[details.royaltyAddress];
        address royaltyAdapter;
        
        require(i_payMaster.checkTickerExist(details.ticker), "Ticker not accepted");

        if (details.royaltyType == 0){   
            IPicardyNftRoyaltySale royalty = IPicardyNftRoyaltySale(details.royaltyAddress);
            royaltyAdapter = IRoyaltyAdapterFactory(adapterFactory).createAdapter(details.royaltyAddress, details.royaltyType, details.ticker);
            royalty.setupAutomation(registry, details.updateInterval, royaltyAdapter);
            i_payMaster.addRoyaltyData(royaltyAdapter, details.royaltyAddress, details.royaltyType);
        }
        else if (details.royaltyType == 1){
            IPicardyTokenRoyaltySale royalty = IPicardyTokenRoyaltySale(details.royaltyAddress);
            royaltyAdapter = IRoyaltyAdapterFactory(adapterFactory).createAdapter(details.royaltyAddress, details.royaltyType, details.ticker);
            royalty.setupAutomation(registry, details.updateInterval, royaltyAdapter);
            i_payMaster.addRoyaltyData(royaltyAdapter, details.royaltyAddress, details.royaltyType);
        }

        (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
        uint256 oldNonce = state.nonce;
        PayloadDetails memory payloadDetails = PayloadDetails(details.name, encryptedEmail, details.royaltyAddress, details.gasLimit, details.adminAddress, "0x", details.amount, 0);
        bytes memory payload = _getPayload(payloadDetails);

        i_link.transferAndCall(registrar, details.amount, bytes.concat(registerSig, payload));
        
        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(keccak256(abi.encodePacked( blockhash(block.number - 1), address(i_registry), uint32(oldNonce))));
                
            i_registeredDetails.royaltyAddress = payable(details.royaltyAddress);
            i_registeredDetails.adapterAddress = royaltyAdapter;
            i_registeredDetails.adminAddress = details.adminAddress;
            i_registeredDetails.upkeepId = upkeepID;

            emit AutomationRegistered(details.royaltyAddress);
        } else {
            revert("auto-approve disabled");
        }
    }

    function getRegisteredDetails(address royaltyAddress) external view returns(RegisteredDetails memory) {
        return registeredDetails[royaltyAddress];
    }

    function _getPayload(PayloadDetails memory payloadDetails) internal view returns(bytes memory){
        bytes memory payload = abi.encode(
            payloadDetails.name, 
            payloadDetails.encryptedEmail, 
            payloadDetails.royaltyAddress, 
            payloadDetails.gasLimit, 
            payloadDetails.adminAddress, 
            payloadDetails.checkData, 
            payloadDetails.amount, 
            payloadDetails.source, 
            address(this)
        );

        return payload;
    }
}

interface IRoyaltyAutomationRegistrar {
    struct RegistrationDetails {
        string name;
        string ticker;
        string email;
        address royaltyAddress;
        address adminAddress;
        uint royaltyType;
        uint updateInterval;
        uint32 gasLimit;
        uint96 amount;
    }

    struct RegisteredDetails {
        address royaltyAddress;
        address adapterAddress;
        address adminAddress;
        uint upkeepId;
    }
    
    function register(RegistrationDetails memory details) external;

    function getRegisteredDetails(address royaltyAddress) external view returns(RegisteredDetails memory);
}
