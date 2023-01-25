// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/// @title Royalty Adapter V2
/// @author joshua Obigwe

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {IPicardyNftRoyaltySaleV3} from "../ProductsV3/NftRoyaltySaleV3.sol";
import {IPayMaster} from "../AutomationV3/PayMasterV3.sol";
import {IPicardyTokenRoyaltySaleV3} from "../ProductsV3/TokenRoyaltySaleV3.sol";
import {IPicardyHub} from "../../PicardyHub.sol";
import {IRoyaltyAutomationRegistrarV3} from "../AutomationV3/RoyaltyAutomationRegV3.sol";


contract RoyaltyAdapterV3 is ChainlinkClient, AutomationCompatibleInterface {
    using Chainlink for Chainlink.Request;
    using Strings for uint256;

    event RoyaltyData(bytes32 indexed requestId, uint indexed value, uint indexed royaltyAutomationId);
    event UpkeepPerformed(uint indexed time);

    uint256 private ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY / 10; // 1.0  * 10**18
    uint256 private KEEPERS_FEE = 1 * LINK_DIVISIBILITY / 10; // 1.0  * 10**18
    address payMaster;
    address public picardyReg;
    address public picardyHub;
    address public linkAddress;

    struct AutomationDetails {
       address royaltyAddress;
       address oracle;
       uint royaltyType;
       uint updateInterval;
       string jobId;
       uint royaltyAutomationId;
    }

    mapping(address => bool) public saleExists;
    mapping(address => uint) public linkBalance;
    mapping (address => AutomationDetails) public automationDetails;
    mapping (uint => AutomationDetails) public idToAutomationDetails;
    address[] registeredAddresses;

    uint royaltyAutomationId = 1;


    LinkTokenInterface immutable LINK;
    IRoyaltyAutomationRegistrarV3 i_royaltyReg;
    constructor(address _linkToken, address _payMaster, address _picardyHub) {
        require(IPicardyHub(_picardyHub).checkHubAdmin(msg.sender) == true, "addAdapterDetails: not hubAdmin");
        payMaster = _payMaster;
        picardyHub = _picardyHub;
        setChainlinkToken(_linkToken);
        LINK = LinkTokenInterface(_linkToken);
        // Link Mumbai 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    }

    // call this after the contract is deployed
    /// @notice This function is called by the Picardy Hub Admin to add the picardyReg address
    /// @param _picardyReg The address of the Picardy Royalty Automation Registrar
    function addPicardyReg(address _picardyReg) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "addAdapterDetails: not hubAdmin");
        picardyReg = _picardyReg;
        i_royaltyReg = IRoyaltyAutomationRegistrarV3(_picardyReg);
    }

    /// @notice this function is called on registration of automation
    /// @param royaltySaleAddress The address of the royalty sale contract
    /// @dev this function should only be called by the picardy automation Registrar
    function addValidSaleAddress(address royaltySaleAddress, uint royaltyType, uint updateInterval, address oracle, string  calldata jobId, uint amount) external {
        require(msg.sender == picardyReg, "addValidSaleAddress: not picardyReg");
        require(royaltySaleAddress != address(0), "addValidSaleAddress: royalty sale address cannot be address(0)");
        require(royaltyType == 0 || royaltyType == 1, "addValidSaleAddress: royalty type not valid");
        require(oracle != address(0), "addValidSaleAddress: oracle address cannot be address(0)");
        require(bytes(jobId).length > 0, "addValidSaleAddress: jobId cannot be empty");
        automationDetails[royaltySaleAddress] = AutomationDetails({
            royaltyAddress: royaltySaleAddress,
            oracle: oracle,
            royaltyType: royaltyType,
            updateInterval: updateInterval,
            jobId: jobId,
            royaltyAutomationId: royaltyAutomationId});
            linkBalance[royaltySaleAddress] = amount;

        idToAutomationDetails[royaltyAutomationId] = AutomationDetails({
            royaltyAddress: royaltySaleAddress,
            oracle: oracle,
            royaltyType: royaltyType,
            updateInterval: updateInterval,
            jobId: jobId,
            royaltyAutomationId: royaltyAutomationId});

        royaltyAutomationId++;
        registeredAddresses.push(royaltySaleAddress);
        saleExists[royaltySaleAddress] = true;
    }

    function getAddressById(uint _royaltyAutomationId) external view returns (address) {
        return idToAutomationDetails[_royaltyAutomationId].royaltyAddress;
    }

    function getIdByAddress(address _royaltySaleAddress) external view returns (uint) {
        return automationDetails[_royaltySaleAddress].royaltyAutomationId;
    }

    /// @notice this function is called to check the validity of the royalty sale address
    /// @param _royaltySaleAddress The address of the royalty sale contract
    function checkIsValidSaleAddress(address _royaltySaleAddress) external view returns (bool) {
        return saleExists[_royaltySaleAddress];
    }

    /// @notice this function is called by a valid royalty sale contract to request the royalty amount to be sent to the paymaster
    /// @param _royaltySaleAddress The address of the royalty sale contract
    /// @param _oracle The address of the oracle
    /// @param _royaltyType The type of royalty sale
    /// @param _jobId The job id of the oracle
    /// @dev this function should only be called by a registered royalty sale contract
    function requestRoyaltyAmount(address _royaltySaleAddress, address _oracle, uint _royaltyType, string memory _jobId) internal {
        (, uint link) = contractBalances();
        require (link > ORACLE_PAYMENT, "requestRoyaltyAmount: Adapter balance low");
        require (_royaltySaleAddress != address(0), "requestRoyaltyAmount: royalty sale address cannotbe address(0)");
        require (_oracle != address(0), "requestRoyaltyAmount: oracle address cannot be address(0)");
        require (_royaltyType == 0 || _royaltyType == 1, "requestRoyaltyAmount: royalty type not valid");
        require (saleExists[_royaltySaleAddress] == true, "requestRoyaltyAmount: royalty sale registered");
        require (linkBalance[_royaltySaleAddress] >= ORACLE_PAYMENT, "requestRoyaltyAmount: Link balance low");
        if( _royaltyType == 0){
            require(IPicardyNftRoyaltySaleV3(_royaltySaleAddress).checkAutomation() == true, "royalty adapter: automation not enabled");
             linkBalance[_royaltySaleAddress] -= ORACLE_PAYMENT;
            (,,,string memory _projectTitle,string memory _creatorName) = IPicardyNftRoyaltySaleV3(_royaltySaleAddress).getTokenDetails();

            Chainlink.Request memory req = buildOperatorRequest( stringToBytes32(_jobId), this.fulfillrequestRoyaltyAmount.selector);
            req.add("creatorName", _creatorName);
            req.add("projectTitle", _projectTitle);
            req.add("royaltyAddress", Strings.toHexString(uint256(uint160(_royaltySaleAddress)), 20));
            sendOperatorRequestTo(_oracle, req, ORACLE_PAYMENT);
        }else if(_royaltyType == 1){
            require(IPicardyTokenRoyaltySaleV3(_royaltySaleAddress).checkAutomation() == true, "royalty adapter: automation not enabled");
             linkBalance[_royaltySaleAddress] -= ORACLE_PAYMENT;
            (string memory _projectTitle,string memory _creatorName) = IPicardyTokenRoyaltySaleV3(_royaltySaleAddress).getTokenDetails();
            
            Chainlink.Request memory req = buildOperatorRequest( stringToBytes32(_jobId), this.fulfillrequestRoyaltyAmount.selector);
            req.add("creatorName", _creatorName);
            req.add("projectTitle", _projectTitle);
            req.add("royaltyAddress", Strings.toHexString(uint256(uint160(_royaltySaleAddress)), 20));
            sendOperatorRequestTo(_oracle, req, ORACLE_PAYMENT);
        }  
    }

    ///@notice this function is called by the oracle to fulfill the request and send the royalty amount to the paymaster
    ///@param _requestId The request id from the node.
    ///@param amount The amount of royalty to be sent to the paymaster
    ///@param _royaltyAutomationId the id to the royalty sale contract
    ///@dev this function should only be called by the oracle 
    function fulfillrequestRoyaltyAmount(bytes32 _requestId, uint256 amount, uint  _royaltyAutomationId) public recordChainlinkFulfillment(_requestId) {
        emit RoyaltyData(_requestId, amount, _royaltyAutomationId);

        address _royaltySaleAddress = idToAutomationDetails[_royaltyAutomationId].royaltyAddress;
        string memory ticker = IRoyaltyAutomationRegistrarV3(picardyReg).getRoyaltyTicker(_royaltySaleAddress);
        (bool success) = IPayMaster(payMaster).sendPayment(_royaltySaleAddress, ticker,  amount);  
        require(success == true, "fulfillrequestRoyaltyAmount: payment failed");
    }

    /// @notice this function gets the link token balance of the royalty sale contract
    /// @param _royaltySaleAddress The address of the royalty sale contract
    function getRoyaltyLinkBalance(address _royaltySaleAddress) external view returns(uint){
        return linkBalance[_royaltySaleAddress];
    } 

    function fundLinkBalance(address _royaltySaleAddress, uint _amount) external {
        LinkTokenInterface i_link = LinkTokenInterface(linkAddress);
        i_link.transferFrom(msg.sender, address(this), _amount);
        linkBalance[_royaltySaleAddress] += _amount;
    }

    /// @notice this function is called to get the picardy automation registrar address
    function getPicardyReg() external view returns(address){
        return picardyReg;
    }

    function contractBalances() public view returns (uint256 eth, uint256 link){
        eth = address(this).balance;

        LinkTokenInterface linkContract = LinkTokenInterface(
            chainlinkTokenAddress()
        );
        link = linkContract.balanceOf(address(this));
    }

    function getPayMaster() external view returns(address){
        return payMaster;
    }

    function getChainlinkToken() external view returns (address) {
        return chainlinkTokenAddress();
    }

    ///@notice this function is called to withdraw LINK from the contract and should be called only by the picardy hub admin
    function withdrawLink() external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "royalty adapter: Un-Auth");
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer Link"
        );
    }

    ///@notice this function is called by the royalty admin to take out link balance from the contract
    ///@param _royaltyAddress The address of the royalty contract
    ///@dev this function should only be called by the royalty admin
    function adminWithdrawLink(address _royaltyAddress) external {
        require (linkBalance[_royaltyAddress] != 0, "adminWithdrawLink: no link balance");
        require (msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "adminWithdrawLink: Un-Auth");
        require (LINK.balanceOf(address(this)) >= linkBalance[_royaltyAddress], "adminWithdrawLink: contract balance low");
        (bool success) = LINK.transfer(msg.sender, linkBalance[_royaltyAddress]);
        require(success == true, "adminWithdrawLink: transfer failed");
    }

    ///@notice this function is called to withdraw ETH from the contract and should be called only by the picardy hub admin
    function withdrawBalance() external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "royalty adapter: Un-Auth");
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success == true, "withdrawBalance: transfer failed");
    }

    /// @notice ths function is called to update the oracle payment and should be called only by the picardy hub admin
    function updateOraclePayment(uint256 _newPayment) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "royalty adapter: Un-Auth");
        ORACLE_PAYMENT = _newPayment;
    }

    function updateRoyaltyOracle(address _royaltyAddress, address _newOracle) external {
         require (msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "updateRoyaltyOracle: Un-Auth");
        automationDetails[_royaltyAddress].oracle = _newOracle;
    }

    function updateRoyaltyJobId(address _royaltyAddress, string memory _newJobId) external {
         require (msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "updateRoyaltyJobId: Un-Auth");
        automationDetails[_royaltyAddress].jobId = _newJobId;
    }

    function cancelRequest( bytes32 _requestId, uint256 _payment, bytes4 _callbackFunctionId, uint256 _expiration) public {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "royalty adapter: Un-Auth");
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    /// @notice This function is used by chainlink keepers to check if the requirements for upkeep are met
    /// @dev this function can only be called by chainlink keepers
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData){   
        
        address[] memory needsUpkeep = new address[](registeredAddresses.length);
        uint validCount = 0;
        
        for(uint i = 0; i < registeredAddresses.length; i++){
            require(registeredAddresses[i] != address(0), "royalty adapter: address not registered");
            address _royaltyAddress = registeredAddresses[i];
            AutomationDetails memory _automationDetails = automationDetails[_royaltyAddress];
            require(_automationDetails.royaltyType == 0 || _automationDetails.royaltyType == 1, "royalty adapter: invalid royalty type");
            if(_automationDetails.royaltyType == 0){
               IPicardyNftRoyaltySaleV3 _nftRoyaltySale = IPicardyNftRoyaltySaleV3(_royaltyAddress);
                require(_nftRoyaltySale.checkRoyaltyState() == false, "royalty sale open");
                require(_nftRoyaltySale.checkAutomation() == true, "automation not started");
                bool _check = (_nftRoyaltySale.getLastRoyaltyUpdate() + _automationDetails.updateInterval) >= block.timestamp;
                if (_check == true){
                    needsUpkeep[i] = _royaltyAddress;
                    validCount++;
                }
            } else if(_automationDetails.royaltyType == 1){
                IPicardyTokenRoyaltySaleV3 _tokenRoyaltySale = IPicardyTokenRoyaltySaleV3(_royaltyAddress);
                require(_tokenRoyaltySale.checkRoyaltyState() == false, "royalty sale open");
                require(_tokenRoyaltySale.checkAutomation() == true, "automation not started");
                bool _check = (_tokenRoyaltySale.getLastRoyaltyUpdate() + _automationDetails.updateInterval) >= block.timestamp;
                if (_check == true){
                    needsUpkeep[i] = _royaltyAddress;
                    validCount++;
                }
            }
        }

        if (validCount != 0){
        uint cost = KEEPERS_FEE / validCount;
        performData = abi.encode(needsUpkeep, cost);
        upkeepNeeded = true;
        }
        
        return (upkeepNeeded, performData);
    }

    /// @notice This function is used by chainlink keepers to perform upkeep if checkUpkeep() returns true
    /// @dev this function can be called by anyone. checkUpkeep() parameters again to avoid unautorized call.
    function performUpkeep( bytes calldata performData) external override {
        (address[] memory _royaltyAddresses, uint cost) = abi.decode(performData, (address[], uint));
        for (uint i = 0; i < _royaltyAddresses.length; i++) {
            address _royaltyAddress = _royaltyAddresses[i];
            require(_royaltyAddress != address(0), "royalty adapter: address not registered");
            require(linkBalance[_royaltyAddress] >= ORACLE_PAYMENT + KEEPERS_FEE, "royalty adapter: royalty Link Balance low");
            AutomationDetails memory _automationDetails = automationDetails[_royaltyAddress];
            if(_automationDetails.royaltyType == 0){
                IPicardyNftRoyaltySaleV3 _nftRoyaltySale = IPicardyNftRoyaltySaleV3(_royaltyAddress);
                require(_nftRoyaltySale.checkRoyaltyState() == false, "royalty sale open");
                require(_nftRoyaltySale.checkAutomation() == true, "automation not started");
                bool _check = (_nftRoyaltySale.getLastRoyaltyUpdate() + _automationDetails.updateInterval) >= block.timestamp;
                if (_check == true){
                    linkBalance[_royaltyAddress] -= cost;
                    requestRoyaltyAmount(_royaltyAddress, _automationDetails.oracle, _automationDetails.royaltyType, _automationDetails.jobId);
                    emit UpkeepPerformed(block.timestamp);
                }
            } else if(_automationDetails.royaltyType == 1){
                IPicardyTokenRoyaltySaleV3 _tokenRoyaltySale = IPicardyTokenRoyaltySaleV3(_royaltyAddress);
                require(_tokenRoyaltySale.checkRoyaltyState() == false, "royalty sale open");
                require(_tokenRoyaltySale.checkAutomation() == true, "automation not started");
                bool _check = (_tokenRoyaltySale.getLastRoyaltyUpdate() + _automationDetails.updateInterval) >= block.timestamp;
                if (_check == true){
                    linkBalance[_royaltyAddress] -= cost;
                    requestRoyaltyAmount(_royaltyAddress, _automationDetails.oracle, _automationDetails.royaltyType, _automationDetails.jobId);
                    emit UpkeepPerformed(block.timestamp);
                }
            }
        }
    }

    receive() external payable {}
}

interface IRoyaltyAdapterV3{
    function requestRoyaltyAmount(address _royaltySaleAddress, address _oracle, uint _royaltyType, string memory _jobId) external;
    function updateRoyalty(uint _amount) external;
    function checkIsValidSaleAddress(address _royaltySaleAddress) external view returns (bool);	
    function getPicardyReg() external view returns(address);
    function getPayMaster() external view returns(address);
    function addValidSaleAddress(address _royaltySaleAddress, uint _royaltyType, uint _updateIntervals, address _oracle, string calldata _jobId, uint amount) external;
    function getRoyaltyLinkBalance(address _royaltySaleAddress) external view returns(uint);
    function adminWithdrawLink(address _royaltyAddress) external;
    function withdrawBalance() external;
    function updateOraclePayment(uint256 _newPayment) external;
}


//0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec = operatr
//42b90f5bf8b940029fed6330f7036f01 = jobid
//0xdeba4845DdE1E5AAf0eD88053b8Ab5D73A811f7b = oracle