// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// @title Picardy Protocol Hub Contract
/// @author Blok_hamster  
/// @notice This contract is the hub of the Picardy Protocol. It is the admin access to the protocol the Picardy Protocol.
contract PicardyHub is AccessControlEnumerable {

    event FactoryAdded(string  factoryName, address factoryAddress);
    event FactoryRemoved(address factoryAddress);
    event RoyaltyAddressUpdated(address royaltyAddress);

    bytes32 public constant HUB_ADMIN_ROLE = keccak256("HUB_ADMIN_ROLE");
    mapping (string => address) public factories;
    mapping (address => bool) public isFactory;
    address[] public depricatedFactories;
    address royaltyAddress;
    
    modifier onlyAdmin {
        _isHubAdmain();
        _;
    }
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(HUB_ADMIN_ROLE, _msgSender());
    }
    /// @notice This function is used to add a new factory to the protocol.
    /// @param _factoryName The name of the factory to be added.
    /// @param _factoryAddress The address of the factory to be added.
    function addFactory(string calldata _factoryName, address _factoryAddress) external onlyAdmin {
        factories[_factoryName] = _factoryAddress;
        isFactory[_factoryAddress] = true;
        emit FactoryAdded(_factoryName, _factoryAddress);
    }
    /// @notice This function is used to update the royalty address for the protocol.
    /// @param _royaltyAddress The address for recieving royalty to the protocol.
    function updateRoyaltyAddress(address _royaltyAddress) external onlyAdmin {
        require(_royaltyAddress != address(0), "Royalty address cannot be zero address");
        royaltyAddress = _royaltyAddress;
        emit RoyaltyAddressUpdated(_royaltyAddress);
    }

    function getRoyaltyAddress() external view returns(address){
        return royaltyAddress;

    }

    function checkHubAdmin(address addr) external view returns(bool){
        if (hasRole(HUB_ADMIN_ROLE, addr)){
            return true;
        } else {
            return false;
        }
    }

    /// @notice This function is used to add depricated factories to the protocol.
    /// @param _factoryAddress The address of the factory to be depricated.
    function depricateFactory(address _factoryAddress) external onlyAdmin{
        require(isFactory[_factoryAddress], "Factory does not exist");
        depricatedFactories.push(_factoryAddress);
        emit FactoryRemoved(_factoryAddress);
    }

    function getHubAddress() external view returns(address) {
        return address(this);
    }

    function _isHubAdmain() internal view {
        require(hasRole(HUB_ADMIN_ROLE, _msgSender()), "Not Admin");
    }
}

interface IPicardyHub {
    function addFactory(string calldata _factoryName, address factoryAddress) external;
    function updateRoyaltyAddress(address _royaltyAddress) external;
    function checkHubAdmin(address addr) external returns(bool);
    function getRoyaltyAddress() external view returns(address);
    function getHubAddress() external view returns(address);
}