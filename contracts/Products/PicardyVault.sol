
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../Tokens/VSToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IVaultFactory} from "../Factory/PicardyVaultFactory.sol";


/// @title Picardy Vault Contract
/// @author Blok_hamster  
/// @notice This contract is the hub of the Picardy Protocol. It is the admin access to the protocol the Picardy Protocol.
contract PicardyVault is Ownable {

    event FundsWithdrawn(uint indexed amount, address indexed to);
    event NewFundInvestor(address indexed investor);
    event SharesIncreased(address indexed investor, uint indexed amount);
    event VaultStarted(address indexed creator);
    event ShareHolderWithdrawn(address indexed investor, uint indexed amount);
    
    struct VaultDetails {
       uint vaultPoolBalance;
       uint vaultReturnBalance;
        address vsToken;
        address vaultAddress;
        address vaultFactory;
        address[] vaultMembers;
    }

    VaultDetails vaultDetails;
    
    
    //mapping (address => uint) UserShares;
    mapping (address => uint) public userLastDeposit;
    mapping (address => bool) public isVaultMember;
    mapping (address => uint) public vaultPoolDeposit;
    mapping (address => uint) public memberReturnBalance;
    

    constructor (address _vaultCreator, address _vaultFactory) {
        vaultDetails.vaultFactory = _vaultFactory;
        vaultDetails.vaultFactory = _vaultFactory;
        transferOwnership(_vaultCreator);
    }

    function start() external onlyOwner {
        _start();
        emit VaultStarted(_msgSender());
    }

    function joinVault() external payable {
        require(isVaultMember[_msgSender()] == false);
       require(msg.value > 0);
       vaultDetails.vaultPoolBalance += msg.value;
        vaultPoolDeposit[_msgSender()] += msg.value;
        isVaultMember[_msgSender()] = true;
        vaultDetails.vaultMembers.push(_msgSender());
        _mintShares(msg.value);
        userLastDeposit[msg.sender] = block.timestamp;

        emit NewFundInvestor(_msgSender());
    }

    function increaseShares() external payable{
        require(isVaultMember[msg.sender] == true, "Not A Vault Member");
        require(msg.value > 0);
        vaultDetails.vaultPoolBalance += msg.value;
        vaultPoolDeposit[_msgSender()] += msg.value;
        _mintShares(msg.value);
        userLastDeposit[_msgSender()] = block.timestamp;

        emit SharesIncreased(_msgSender(), msg.value);
    }

    function getSharesValue() external view returns (uint){
        return memberReturnBalance[_msgSender()];
    }

    function updateVaultReturn() external payable onlyOwner {
        require(msg.value > 0);
        uint total = msg.value;
        for(uint i = 0; i < vaultDetails.vaultMembers.length; i++){
        uint userShares = IERC20(vaultDetails.vsToken).balanceOf(vaultDetails.vaultMembers[i]);
        uint totalSupply = IERC20(vaultDetails.vsToken).totalSupply();
        uint valuePerShare = total / totalSupply; 
        uint userShareValue = userShares * valuePerShare;
        memberReturnBalance[vaultDetails.vaultMembers[i]] += userShareValue;
        }

        vaultDetails.vaultReturnBalance += msg.value;
    }

    function shareHolderWidrawal(uint _amount) external {
        require(address(this).balance >= _amount);
        require(isVaultMember[_msgSender()] == true);
        require(memberReturnBalance[_msgSender()] >= _amount);
        memberReturnBalance[_msgSender()] -= _amount;
        (bool os, ) = payable(_msgSender()).call{value: _amount}("");
        emit ShareHolderWithdrawn(_msgSender(), _amount);
        require(os);
    }

    function withdraw() external onlyOwner returns(bool){
        require(address(this).balance >= vaultDetails.vaultPoolBalance);
        (address royaltyAddress, uint royaltyPercentage) = IVaultFactory(vaultDetails.vaultFactory).getRoyaltyDetails();
        uint balance = vaultDetails.vaultPoolBalance;
        uint txFee = (balance * royaltyPercentage) / 100;
        uint toWithdraw = balance - txFee;
        address _owner = payable(owner());
        (bool hs, ) = payable(royaltyAddress).call{value: txFee}("");
        (bool os, ) = _owner.call{value: toWithdraw}("");
        require(hs);
        require(os);
        emit FundsWithdrawn(address(this).balance  , owner());
        return true;
    }

    function isShareHolder(address _shareHoler) external view returns(uint){
        uint side;
        if(IERC20(vaultDetails.vsToken).balanceOf(_shareHoler) > 0){
            side = 1;
        } else {
            side = 0;
        }

        return side;
    }

    function getVaultBalance() external view returns(uint){
        return address(this).balance;
    }


    function getShareAmount() external view returns(uint){
        return IERC20(vaultDetails.vsToken).balanceOf(_msgSender());
    }


    function getVaultSharesAddress() external view returns(address){
        return vaultDetails.vsToken;
    }
    
    // INTERNAL FUNCTIONS//
    function _start() internal {
        VSToken newVSToken = new VSToken();
        vaultDetails.vsToken = address(newVSToken);
    }


    function _mintShares(uint _amount) internal {
        uint shares;
        uint totalSupply = IERC20(vaultDetails.vsToken).totalSupply();

        if(totalSupply == 0 ){
            shares = _amount;
            _mint(shares);
        } else {
            shares = (_amount * totalSupply) / vaultDetails.vaultPoolBalance;
            _mint(shares);
        }
       
    }

    function _mint(uint _amount) internal {
        VSToken newVSToken = VSToken(vaultDetails.vsToken);
        newVSToken.mint(_amount, _msgSender());
    }

    function burnShares() external returns(address, uint){
        uint userShares = IERC20(vaultDetails.vsToken).balanceOf(_msgSender());
        ( , uint royaltyPercentage) = IVaultFactory(vaultDetails.vaultFactory).getRoyaltyDetails();
        uint txFee = (vaultPoolDeposit[_msgSender()] * royaltyPercentage) / 100;
        uint toWithdraw = vaultPoolDeposit[_msgSender()] - txFee;
        uint totalShareValue = memberReturnBalance[_msgSender()] + toWithdraw;
        require(address(this).balance >= totalShareValue);
        _burn(userShares);
        (bool os, ) = payable(_msgSender()).call{value: totalShareValue}("");
        require(os);
        return(_msgSender(), userShares);
    }


    function _burn(uint _sharesToBurn) internal {
        VSToken newVSToken = VSToken(vaultDetails.vsToken);
        newVSToken.burn(_sharesToBurn, _msgSender());
    }

}

interface IPicardyVault{
/// @dev starts the vault contract
    function start() external;

    /// @dev allows a user to join the vault
    function joinVault() external payable;

    /// @dev allows a user to increase their shares
    function increaseShares() external payable;

    /// @dev allows a user to withdraw their shares
    function burnShares() external returns(address, uint);

    /// @dev allows the vault owner to withdraw the vault funds
    function withdraw() external returns(bool);

    /// @dev allows the vault owner to update the vault return
    function updateVaultReturn() external payable ;

    /// @dev allows a user to withdraw their vault return
    function shareHolderWidrawal(uint _amount) external;

    /// @dev allows a user to check if they are a vault member
    function isShareHolder(address _shareHoler) external view returns(uint);

    /// @dev allows a user to check their vault balance
    function getVaultBalance() external view returns(uint);

    /// @dev allows a user to check their share amount
    function getShareAmount() external view returns(uint);

    /// @dev allows a user to check the vault shares address
    function getVaultSharesAddress() external view returns(address);

    /// @dev allows a user to check their vault return balance
    function getSharesValue() external view returns (uint);
} 