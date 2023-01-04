// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract GovernanceTimeLock is TimelockController {
    // minDelay is how long in blocks you have to wait before executing 
    // proposers is the list of addresses that can propose
    // executors is the list of addresses that can execute
    constructor (
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address _admin
    ) TimelockController (minDelay, proposers, executors, _admin) {}
}