// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IPicardyNftRoyaltySale} from "../Products/NftRoyaltySale.sol";
import {IPicardyTokenRoyaltySale} from "../Products/TokenRoyaltySale.sol";
import {IPayMaster} from "../Automation/PayMaster.sol";
import {IRoyaltyAdapterFactory} from "../Factory/RoyaltyAdapterFactory.sol";

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

contract RegisterAutomation {

    struct RegisteredDetails{
    address payable royaltyAddress;
    address adapterAddress;
    address adminAddress;
    uint upkeepId;
    uint royaltyType;
    }
    
    address public link;
    address public registry;
    address public registrar;
    address adapterFactory;
    address public picardyHub;
    address public payMaster;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    mapping (address => RegisteredDetails) public registeredDetails;
    mapping (string => bool) tickerExists;

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
        adapterFactory = _adapterFactory;
    }

    function addTicker(string memory ticker) public {
        require(tickerExists[ticker] == false, "Ticker already exists");
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "Not a hub admin");
        tickerExists[ticker] = true;
    }

    function register(
        string memory name,
        string memory ticker,
        string calldata email,
        address royaltyAddress,
        uint royaltyType,
        uint updateInterval,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source
    ) public {

        bytes memory encryptedEmail = abi.encode(email);
        IPayMaster i_payMaster = IPayMaster(payMaster);
        LinkTokenInterface i_link = LinkTokenInterface(link);
        AutomationRegistryInterface i_registry = AutomationRegistryInterface(
            registry
        );
        
        require(i_payMaster.checkTickerExist(ticker), "Ticker not accepted");

        if (tokenType == 0){   
            IPicardyNftRoyaltySale royalty = IPicardyNftRoyaltySale(royaltyAddress);
            address royaltyAdapter = IRoyaltyAdapterFactory(adapterFactory).createAdapter(royaltyAddress,royaltyType, ticker);
            royalty.setupAutomation(registry, updateInterval, royaltyAdapter);
            i_payMaster.addRoyaltyData(royaltyAdapter, royaltyAddress, royaltyType);
            
            (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
            uint256 oldNonce = state.nonce;
            bytes memory payload = abi.encode( name, encryptedEmail, royaltyAddress, gasLimit, adminAddress, "0x", amount, 0, address(this));

            i_link.transferAndCall(registrar, amount, bytes.concat(registerSig, payload));
            (state, _c, _k) = i_registry.getState();
            uint256 newNonce = state.nonce;
            if (newNonce == oldNonce + 1) {
                uint256 upkeepID = uint256(keccak256(abi.encodePacked( blockhash(block.number - 1), address(i_registry), uint32(oldNonce))));
                RegisteredDetails i_registeredDetails = RegisteredDetails(royaltyAddress, royaltyAdapter, adminAddress, upkeepID, royaltyType);
                registeredDetails[royaltyAddress] = i_registeredDetails;
            } else {
                revert("auto-approve disabled");
            }
        }
        else if (tokenType == 1){
            IPicardyNftRoyaltySale royalty = IPicardyTokenRoyaltySale(royaltyAddress);
            address royaltyAdapter = ITokenRoyaltyAdapterFactory(adapterFactory).createAdapter(royaltyAddress,royaltyType, ticker);
            royalty.setupAutomation(registry, updateInterval, royaltyAdapter);
            i_payMaster.addRoyaltyData(royaltyAdapter, royaltyAddress, royaltyType);
            
            (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
            uint256 oldNonce = state.nonce;
            bytes memory payload = abi.encode( name, encryptedEmail, royaltyAddress, gasLimit, adminAddress, "0x", amount, 0, address(this));

            i_link.transferAndCall( registrar, amount, bytes.concat(registerSig, payload));
            (state, _c, _k) = i_registry.getState();
            uint256 newNonce = state.nonce;
            if (newNonce == oldNonce + 1) {
                uint256 upkeepID = uint256( keccak256( abi.encodePacked( blockhash(block.number - 1), address(i_registry), uint32(oldNonce))));
                RegisteredDetails i_registeredDetails = RegisteredDetails(royaltyAddress, royaltyAdapter, adminAddress, upkeepID, royaltyType);
                registeredDetails[royaltyAddress] = i_registeredDetails;
            } else {
                revert("auto-approve disabled");
            }
        }
  
    }
}
