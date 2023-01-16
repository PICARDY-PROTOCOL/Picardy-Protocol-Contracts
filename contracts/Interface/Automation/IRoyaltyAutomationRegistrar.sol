// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

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

    function fundAutomation(address royaltyAddress, uint96 amount) external;

    function cancleAutomation(address royaltyAddress, uint _royaltyType) external;

    function resetAutomation(RegistrationDetails memory details) external;

    function getRegisteredDetails(address royaltyAddress) external view returns(RegisteredDetails memory);
}