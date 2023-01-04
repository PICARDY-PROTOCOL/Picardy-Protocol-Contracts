// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Governance/GovonorControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../PicardyHub.sol";
import {ITimelockFactory} from "./TimeLockFactory.sol";

contract DaoFactory is Context {
    
    event DaoCreated(uint indexed daoId, string indexed daoName, address indexed creator);
    event DaoFactoryPrice(uint indexed price);
    struct DaoDetails {
        uint Id;
        uint votePeriod;
        uint qurouPercentage;
        address creator; 
        address token;
        string name;   
    }

    uint voteDelay = 0;
    uint minDelay = 1;
    uint daoId = 1;
    uint price;

    address picardyHub;
    address timelockFactory;

    mapping(string => address) public timeLockMap;
    mapping(string => address) public governorMap;
    mapping(string => DaoDetails) public daoDetails;
    mapping(string => bool) public daoExists;

    constructor (address _picardyHub) {
        picardyHub = _picardyHub;
    }

    
    function getVotePeriod(uint _votePeriod) internal pure returns (uint) {
        uint vPeriod = (24*60*60)/12;
        uint votePeriod = _votePeriod * vPeriod;
            return votePeriod;
    }

    function setPrice(uint _price) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()) == true, " not hub admin");
        price = _price;
        emit DaoFactoryPrice(_price);
    }

    function createDao(string calldata _name, uint _votePeriod, uint _qurouPercentage, address _creator, address _token) external payable {
        require (!daoExists[_name], "DaoExists");
        require(_creator != address(0), "creator cannot be zero address");
        require(_token != address(0), "vote token cannot be zero address");
        require(msg.value >= price, "insufficient balance");

        daoDetails[_name].votePeriod = _votePeriod;
        daoDetails[_name].qurouPercentage = _qurouPercentage;
        daoDetails[_name].name = _name;
        daoDetails[_name].token = _token;
        daoDetails[_name].Id = daoId;
        daoDetails[_name].creator = _creator;
        daoExists[_name] = true;
    }

    function initDao (string calldata _name) external payable returns (address, address, uint) {
    DaoDetails memory dao = daoDetails[_name];
    require(dao.creator == _msgSender(), "not creator");
    require(daoExists[_name]);
    require(msg.value >= price);
    require(dao.creator != address(0));
    require(dao.token != address(0));
    (address timeLock, address govonor, uint _daoId) = _initDao(_name, _msgSender());
    return (timeLock, govonor, _daoId);
    }

    function _initDao( string calldata _name, address _admin) internal returns (address, address, uint) {
        DaoDetails memory dao = daoDetails[_name];
        uint votePeriod = getVotePeriod(dao.votePeriod);
        //import timelock factory and get timelock address based on dao name
        (address timeLockAddress) = ITimelockFactory(timelockFactory).createTimelock(_name,_admin);
        PicardyGovernor governor = new PicardyGovernor(IVotes(dao.token), TimelockController(payable(timeLockAddress)), votePeriod, voteDelay, dao.qurouPercentage);
        address governorAddress = address(governor);
        governorMap[_name] = governorAddress;
        ITimelockFactory(timelockFactory).updateTimelockRole(_name, governorAddress);
        daoId++;
        emit DaoCreated(daoId, _name, dao.creator);
        return (timeLockAddress, governorAddress, daoId);
    }

    function addTimelockFactoryAddress(address _timelockFactory) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()) == true, " not hub admin");
        timelockFactory = _timelockFactory;
    }


    function getDaoDetails(string calldata _name) external view returns (uint , uint, uint, address) {
        DaoDetails memory dao = daoDetails[_name];
        return (dao.Id, dao.votePeriod, dao.qurouPercentage, dao.creator);
    }

    function getDaoAddresses(string calldata _name) external view returns (address, address){
        address timelock = timeLockMap[_name];
        address governor = governorMap[_name];

        return (timelock, governor);
    }

    function withdraw(address _addr) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()) == true, "not Hub admin");
        (bool os, ) = payable(_addr).call{value: address(this).balance}("");
        require(os);
    }
}

interface IDaoFactory {
    function setPrice(uint _price) external;

    function withdraw(address _addr) external;

    function getDaoDetails(string calldata _name) external view returns (uint , uint, uint, address);

    function addTimelockFactoryAddress(address _timelockFactory) external;

    function initDao (string calldata _name) external payable returns (address, address, uint);

    function createDao(string calldata _name, uint _votePeriod, uint _qurouPercentage, address _creator, address _token) external payable;

    function getDaoAddresses(string calldata _name) external view returns (address, address);
}