/**
    @author Blok Hamster 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";
import "../Products/PicardyVault.sol";

contract PicardyVaultFactory is Context {
    
    event NewVaultCreated(uint indexed vaultId, address indexed vaultAddress);
    event RoyaltyDetailsUpdated(uint percentage, address royaltyAddress);
    
    struct Vault{
        uint Id;
        address vaultAddress;
    }

    mapping (uint => Vault) vaultMap;
    mapping (address => uint) vaultIdMap;
    struct RoyaltyDetails{
        uint royaltyPercentage;
        address royaltyAddress;
    }
    RoyaltyDetails royaltyDetails;
    address picardyHub;

    uint vaultId = 1;

    constructor (address _picardyHub){
        picardyHub = _picardyHub;
    }
    
    function createVault() external returns(uint, address){
        PicardyVault newPicardyVault = new PicardyVault(_msgSender(), address(this));
        uint newVaultId = vaultId;
        Vault memory newVault = Vault(newVaultId, address(newPicardyVault));
        vaultMap[newVaultId] = newVault;
        vaultIdMap[address(newPicardyVault)] = newVaultId;
        vaultId++;
        emit NewVaultCreated(newVaultId, address(newPicardyVault));
        return (newVaultId, address(newPicardyVault));

    }

    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()), "Not Hub Admin");
        address royaltyAddress = IPicardyHub(picardyHub).getRoyaltyAddress();
        RoyaltyDetails memory newRoyaltyDetails = RoyaltyDetails(_royaltyPercentage, royaltyAddress);
        royaltyDetails = newRoyaltyDetails;
        emit RoyaltyDetailsUpdated(_royaltyPercentage, royaltyAddress);
    }

    function getRoyaltyDetails() external view returns (address, uint){
        address royaltyAddress = royaltyDetails.royaltyAddress;
        uint royaltyPercentage = royaltyDetails.royaltyPercentage;
        return(royaltyAddress, royaltyPercentage);
    }

    function getHubAddress() external view returns (address){
        return picardyHub;
    }

    function getVaultAddress(uint _vaultId) external view returns(address){
        return vaultMap[_vaultId].vaultAddress;
    }

    function getVaultId(address _vaultAddress) external view returns(uint){
        return vaultIdMap[_vaultAddress];
    }
}

interface IVaultFactory{
    function createVault(address _vaultToken, string memory _vaultTokenName) external returns(uint, address);
    function getVaultAddress(uint _vaultId) external view returns(address);
    function getVaultId(address _vaultAddress) external view returns(uint);
    function getRoyaltyDetails() external view returns (address, uint);
}
