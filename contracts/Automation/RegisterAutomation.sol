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
    address adminAddress;
    uint upkeepId;
    uint tokenType;
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
        address _link,
        address _registrar,
        address _registry,
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
        bytes calldata encryptedEmail,
        address royaltyAddress,
        uint tokenType,
        uint updateInterval,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source
    ) public {

        LinkTokenInterface i_link = LinkTokenInterface(link);
        AutomationRegistryInterface i_registry = AutomationRegistryInterface(
            registry
        );
        require(tickerExists[ticker] == true, "Ticker not accepted");

        if (tokenType == 0){
            IPicardyNftRoyaltySale royalty = IPicardyNftRoyaltySale(royaltyAddress);
            address royaltyAdapter = IRoyaltyAdapterFactory(adapterFactory).createRoyaltyAdapter(royaltyAddress,tokenType, ticker);
            royalty.setupAutomation(registry, updateInterval, royaltyAdapter);
        }
        else if (tokenType == 1){
            IPicardyTokenRoyaltySale royalty = IPicardyTokenRoyaltySale(royaltyAddress);
            address royaltyAdapter = IRoyaltyAdapterFactory(adapterFactory).createRoyaltyAdapter(royaltyAddress,tokenType, ticker);
            royalty.setupAutomation(registry, updateInterval, royaltyAdapter);
        }
        else{
            revert("Invalid token type");
        }

        (State memory state, Config memory _c, address[] memory _k) = i_registry
            .getState();
        uint256 oldNonce = state.nonce;
        bytes memory payload = abi.encode(
            name,
            encryptedEmail,
            royaltyAddress,
            gasLimit,
            adminAddress,
            checkData,
            amount,
            source,
            address(this)
        );

        i_link.transferAndCall(
            registrar,
            amount,
            bytes.concat(registerSig, payload)
        );
        (state, _c, _k) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
            // DEV - Use the upkeepID however you see fit
        } else {
            revert("auto-approve disabled");
        }
    }
}
