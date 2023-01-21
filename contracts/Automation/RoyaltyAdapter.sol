// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
//import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPicardyNftRoyaltySale} from "../Products/NftRoyaltySale.sol";
import {IPayMaster} from "../Automation/PayMaster.sol";

contract RoyaltyAdapter is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    event RoyaltyData(bytes32 indexed requestId, uint indexed value);

    uint256 private constant ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY; // 1 * 10**18
    string public lastRetrievedInfo;

    address public owner;
    address public oracle;
    address payMaster;
    address public royaltySaleAddress;
    address public picardyReg;
    string public jobId;
    bool public initialized;
    string public ticker;
    

    modifier onlyOwner() {
        require(msg.sender == owner, "royalty adapter: Un-Auth");
        _;
    }

    function initilize(address _linkToken, address _oracle, string memory _jobId, string memory _ticker, address _royaltySaleAddress, address _owner, address _payMaster, address _picardyReg) public {
        require(!initialized, "Already initialized!");
        require(IPicardyNftRoyaltySale(_royaltySaleAddress).getCreator() == _owner, "royalty adapter: Un-Auth , not owner");
        royaltySaleAddress = _royaltySaleAddress;
        jobId = _jobId;
        oracle = _oracle;
        payMaster = _payMaster;
        picardyReg = _picardyReg;
        ticker = _ticker;
        setChainlinkToken(_linkToken);
        owner = _owner;
        initialized = true;
        // Link Mumbai 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
    }

    function updateTicker(string memory _ticker) public onlyOwner {
        ticker = _ticker;
    }

    //This request for the royalty form the royalty database
    function requestRoyaltyAmount() public {
        (, uint link) = contractBalances();
        require (link > ORACLE_PAYMENT,"royalty adapter: link balance low");
        require (msg.sender == royaltySaleAddress , "royalty adapter: Un-Auth");
        (,,,string memory name,string memory creatorName) = IPicardyNftRoyaltySale(royaltySaleAddress).getTokenDetails();

        Chainlink.Request memory req = buildOperatorRequest(
            stringToBytes32(jobId),
            this.fulfillrequestRoyaltyAmount.selector
        );
        req.add("creatorName", creatorName);
        req.add("name", name);
        sendOperatorRequestTo(oracle, req, ORACLE_PAYMENT);
        
    }

    //this function is called to fufil the api request and return the royalty value in whatever ticker is specified. 
    //calls the pay master contract that checks the reserve for the adapter and pay royalty to the royalty contract 
    function fulfillrequestRoyaltyAmount(bytes32 _requestId, uint256 amount)
        public
        recordChainlinkFulfillment(_requestId)
    {
        emit RoyaltyData(_requestId, amount);
        IPayMaster(payMaster).sendPayment(address(this), ticker , amount);
       
    }

    function getTickerAddress() public view returns(address) {
        return IPayMaster(payMaster).getTokenAddress(ticker);
    }

    function getPicardyReg() external view returns(address){
        return picardyReg;
    }

    function contractBalances()
        public
        view
        returns (uint256 eth, uint256 link)
    {
        eth = address(this).balance;

        LinkTokenInterface linkContract = LinkTokenInterface(
            chainlinkTokenAddress()
        );
        link = linkContract.balanceOf(address(this));
    }

    // call this function after contract creation and deposit link for external adapter call
    function initilizeAdapter(address _oracle, string memory _jobId) external onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
    }

    function getRoyaltySaleAddress() public view returns (address) {
        return royaltySaleAddress;
    }

    function getPayMaster() external view returns(address){
        return payMaster;
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer Link"
        );
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    receive() external payable {
      
    }
}

interface IRoyaltyAdapter{
    function requestRoyaltyAmount() external;
    function getRoyaltySaleAddress() external view returns (address);
    function getTickerAddress() external view returns(address);
    function updateRoyalty(uint _amount) external;
    function getPicardyReg() external view returns(address);
    function getPayMaster() external view returns(address);
}


//0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec = operatr
//42b90f5bf8b940029fed6330f7036f01 = jobid
//0xdeba4845DdE1E5AAf0eD88053b8Ab5D73A811f7b = oracle