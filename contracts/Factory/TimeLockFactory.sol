// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Governance/GovernanceTimeLock.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IDaoFactory} from "./DaoFactory.sol";
import {IPicardyHub} from "../PicardyHub.sol";

contract TimelockFactory is Context{
     mapping(string => address) public timeLockMap;
     address daoFactoryAddress;
     address picardyHub;
     uint minDelay = 1;

     constructor(address _picardyHub){
        picardyHub = _picardyHub;
     }

    function createTimelock(string calldata _name, address _admin) external returns (address) {
     require(_msgSender() == daoFactoryAddress, "only Dao factory can call");
    address[] memory _proposers;
    address[] memory _executors;
    GovernanceTimeLock timeLock = new GovernanceTimeLock(minDelay, _proposers, _executors, _admin);
    timeLockMap[_name] = address(timeLock);
    return address(timeLock);
    }

    function updateTimelockRole(string calldata _name, address governorAddress) external {
     require(_msgSender() == daoFactoryAddress, "only Dao factory can call");
     (,,,address _creator) = IDaoFactory(daoFactoryAddress).getDaoDetails(_name);
        address timeLockAddress = timeLockMap[_name];
        GovernanceTimeLock timeLock = GovernanceTimeLock(payable(timeLockAddress));
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.TIMELOCK_ADMIN_ROLE();
        timeLock.grantRole(proposerRole, governorAddress);
        timeLock.grantRole(executorRole, address(0));
        timeLock.grantRole(adminRole, _creator);
        timeLock.revokeRole(adminRole, address(this));
    }

    function addDaoFactoryAddress(address _daoFactoryAddress) external {
         require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()) == true, " not hub admin");
         daoFactoryAddress = _daoFactoryAddress;
    }

    function getTimelockAddress(string calldata _name)external view returns (address){
     return timeLockMap[_name];
    }
}

interface ITimelockFactory {
     function createTimelock(string calldata _name, address _admin) external returns (address);

     function updateTimelockRole(string calldata _name, address govonorAddress) external;

     function getTimelockAddress(string calldata _name)external view returns (address);
}