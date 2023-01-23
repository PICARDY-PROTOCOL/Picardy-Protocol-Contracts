# Solidity API

## PicardyHub

This contract is the hub of the Picardy Protocol. It is the admin access to the protocol the Picardy Protocol.

### FactoryAdded

```solidity
event FactoryAdded(string factoryName, address factoryAddress)
```

### FactoryRemoved

```solidity
event FactoryRemoved(address factoryAddress)
```

### RoyaltyAddressUpdated

```solidity
event RoyaltyAddressUpdated(address royaltyAddress)
```

### HUB_ADMIN_ROLE

```solidity
bytes32 HUB_ADMIN_ROLE
```

### factories

```solidity
mapping(string => address) factories
```

### isFactory

```solidity
mapping(address => bool) isFactory
```

### depricatedFactories

```solidity
address[] depricatedFactories
```

### royaltyAddress

```solidity
address royaltyAddress
```

### onlyAdmin

```solidity
modifier onlyAdmin()
```

### constructor

```solidity
constructor() public
```

### addFactory

```solidity
function addFactory(string _factoryName, address _factoryAddress) external
```

This function is used to add a new factory to the protocol.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _factoryName | string | The name of the factory to be added. |
| _factoryAddress | address | The address of the factory to be added. |

### updateRoyaltyAddress

```solidity
function updateRoyaltyAddress(address _royaltyAddress) external
```

This function is used to update the royalty address for the protocol.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address for recieving royalty to the protocol. |

### getRoyaltyAddress

```solidity
function getRoyaltyAddress() external view returns (address)
```

### checkHubAdmin

```solidity
function checkHubAdmin(address addr) external view returns (bool)
```

### depricateFactory

```solidity
function depricateFactory(address _factoryAddress) external
```

This function is used to add depricated factories to the protocol.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _factoryAddress | address | The address of the factory to be depricated. |

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

### _isHubAdmain

```solidity
function _isHubAdmain() internal view
```

## IPicardyHub

### addFactory

```solidity
function addFactory(string _factoryName, address factoryAddress) external
```

### updateRoyaltyAddress

```solidity
function updateRoyaltyAddress(address _royaltyAddress) external
```

### checkHubAdmin

```solidity
function checkHubAdmin(address addr) external returns (bool)
```

### getRoyaltyAddress

```solidity
function getRoyaltyAddress() external view returns (address)
```

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

## CPToken

### decimal

```solidity
uint256 decimal
```

### owner

```solidity
address owner
```

### holders

```solidity
address[] holders
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### constructor

```solidity
constructor(string _name, address _owner) public
```

### mint

```solidity
function mint(uint256 _amount, address _to) external
```

### transfer

```solidity
function transfer(address recipient, uint256 amount) public returns (bool)
```

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool)
```

### getHolders

```solidity
function getHolders() public view returns (address[])
```

## PicardyNftBase

### Royalty

```solidity
struct Royalty {
  string baseURI;
  string artisteName;
  uint256 maxSupply;
  uint256 maxMintAmount;
  uint256 saleCount;
  uint256 percentage;
  address[] holders;
  address saleAddress;
}
```

### royalty

```solidity
struct PicardyNftBase.Royalty royalty
```

### baseExtension

```solidity
string baseExtension
```

### onlySaleContract

```solidity
modifier onlySaleContract()
```

### constructor

```solidity
constructor(uint256 _maxSupply, uint256 _maxMintAmount, uint256 _percentage, string _name, string _symbol, string _initBaseURI, string _artisteName, address _saleAddress, address _creator) public
```

### _baseURI

```solidity
function _baseURI() internal view virtual returns (string)
```

_Base URI for computing {tokenURI}. If set, the resulting URI for each
token will be the concatenation of the `baseURI` and the `tokenId`. Empty
by default, can be overridden in child contracts._

### buyRoyalty

```solidity
function buyRoyalty(uint256 _mintAmount, address addr) external
```

### holdersTokenIds

```solidity
function holdersTokenIds(address _owner) public view returns (uint256[])
```

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view virtual returns (string)
```

_See {IERC721Metadata-tokenURI}._

### setMaxMintAmount

```solidity
function setMaxMintAmount(uint256 _newmaxMintAmount) external
```

### setBaseURI

```solidity
function setBaseURI(string _newBaseURI) external
```

### setBaseExtension

```solidity
function setBaseExtension(string _newBaseExtension) external
```

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### withdraw

```solidity
function withdraw(address _addr) public
```

### withdrawERC20

```solidity
function withdrawERC20(address _token, address _addr) public
```

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) public
```

_See {IERC721-transferFrom}._

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) public
```

_See {IERC721-safeTransferFrom}._

### _burn

```solidity
function _burn(uint256 tokenId) internal
```

_Destroys `tokenId`.
The approval is cleared when the token is burned.
This is an internal function that does not check if the sender is authorized to operate on the token.

Requirements:

- `tokenId` must exist.

Emits a {Transfer} event._

### getHolders

```solidity
function getHolders() public view returns (address[])
```

### getSaleCount

```solidity
function getSaleCount() public view returns (uint256)
```

### _onlySaleContract

```solidity
function _onlySaleContract() internal view
```

## IPicardyNftBase

### getHolders

```solidity
function getHolders() external view returns (address[])
```

### getSaleCount

```solidity
function getSaleCount() external view returns (uint256)
```

### tokenURI

```solidity
function tokenURI(uint256 tokenId) external view returns (string)
```

## PayMasterV2

### PaymentPending

```solidity
event PaymentPending(address royaltyAddress, string ticker, uint256 amount)
```

### PendingRoyaltyRefunded

```solidity
event PendingRoyaltyRefunded(address royaltyAddress, string ticker, uint256 amount)
```

### RoyaltyPaymentSent

```solidity
event RoyaltyPaymentSent(address royaltyAddress, string ticker, uint256 amount)
```

### picardyHub

```solidity
contract IPicardyHub picardyHub
```

### royaltyReserve

```solidity
mapping(address => mapping(address => mapping(string => uint256))) royaltyReserve
```

### royaltyPending

```solidity
mapping(address => mapping(address => mapping(string => uint256))) royaltyPending
```

### royaltyPaid

```solidity
mapping(address => mapping(address => mapping(string => uint256))) royaltyPaid
```

### isRegistered

```solidity
mapping(address => mapping(address => bool)) isRegistered
```

### royaltyData

```solidity
mapping(address => struct PayMasterV2.RoyaltyData) royaltyData
```

### tokenAddress

```solidity
mapping(string => address) tokenAddress
```

### tickerExist

```solidity
mapping(string => bool) tickerExist
```

### RoyaltyData

```solidity
struct RoyaltyData {
  address adapter;
  address payable royaltyAddress;
  uint256 royaltyType;
  string ticker;
}
```

### i_royaltyReg

```solidity
contract IRoyaltyAutomationRegistrarV2 i_royaltyReg
```

### constructor

```solidity
constructor(address _picardyHub) public
```

### addToken

```solidity
function addToken(string _ticker, address _tokenAddress) external
```

Add a new token to the PayMaster

_Only the PicardyHub admin can call this function_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _ticker | string | The ticker of the token |
| _tokenAddress | address | The address of the token |

### addRegAddress

```solidity
function addRegAddress(address _picardyReg) external
```

adds the picardyRegistrar address to the PayMaster

_Only the PicardyHub admin can call this function_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _picardyReg | address | The address of the picardyRegistrar |

### removeToken

```solidity
function removeToken(string _ticker) external
```

Remove a token from the PayMaster

_Only the PicardyHub admin can call this function_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _ticker | string | The ticker of the token |

### addRoyaltyData

```solidity
function addRoyaltyData(address _adapter, address _royaltyAddress, uint256 royaltyType, string ticker) external
```

registers a new royalty to the paymaster

_Only the picardyRegistrar can call this function on automation registration_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _adapter | address | The address for picardy royalty adapter |
| _royaltyAddress | address | The address of the royalty sales contract |
| royaltyType | uint256 | The type of royalty (0 = NFT, 1 = Token) |
| ticker | string | The ticker of the token to be paid to the royalty holders from pay master (e.g. ETH, USDC, etc) |

### removeRoyaltyData

```solidity
function removeRoyaltyData(address _adapter, address _royaltyAddress) external
```

removes a royalty from the paymaster

_Only the picardyRegistrar can call this function on automation cancellation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _adapter | address | The address for picardy royalty adapter |
| _royaltyAddress | address | The address of the royalty sales contract |

### addETHReserve

```solidity
function addETHReserve(address _royaltyAddress, uint256 _amount) external payable
```

updates the ETH reserve for payment of royalty splits to royalty holders

_This function can be called by anyone as it basically just adds ETH to the royalty reserve_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _amount | uint256 | The amount of ETH to be added to the reserve |

### addERC20Reserve

```solidity
function addERC20Reserve(address _royaltyAddress, string _ticker, uint256 _amount) external
```

updates the ERC20 reserve for payment of royalty splits to royalty holders

_This function can be called by anyone as it basically just adds tokens to the royalty reserve_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _ticker | string | The ticker of the token to be added to the reserve |
| _amount | uint256 | The amount of tokens to be added to the reserve |

### withdrawReserve

```solidity
function withdrawReserve(address _royaltyAddress, string _ticker, uint256 _amount) external
```

withdraws the ETH reserve for payment of royalty splits to royalty holders

_This function can only be called by the royalty contract admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _ticker | string |  |
| _amount | uint256 | The amount of ETH to be withdrawn from the reserve |

### sendPayment

```solidity
function sendPayment(address _royaltyAddress, string _ticker, uint256 _amount) external returns (bool)
```

sends the royalty payment to the royalty sale contract to be distributed to the royalty holders

_This function can only be called by picardy royalty adapter, With the amount being the return form chainlink node.
The amount is then multiplied by the royalty percentage to get the amount to be sent to the royalty sales contract
if the reserve balance of the token is less than the amount to be sent, the amount is added to the pending payments_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _ticker | string | The ticker of the token to be sent to the royalty sales contract |
| _amount | uint256 | The amount to be sent to the royalty sales contract |

### _royaltyPercentage

```solidity
function _royaltyPercentage(address _royaltyAddress, uint256 _royaltyType) internal view returns (uint256)
```

gets the royalty percentage from the royalty sales contract and converts it to bips

_This is internal view function and doesnt write to state._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _royaltyType | uint256 | The type of royalty sales contract |

### refundPending

```solidity
function refundPending(address _royaltyAddress, string _ticker, uint256 _amount) external
```

Refunds the pending unpaid royalty to the royalty sales contract

_this function should be called by the royalty sale contract admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _ticker | string | The ticker of the token to be sent to the royalty sales contract |
| _amount | uint256 | The amount to be sent to the royalty sales contract |

### getETHReserve

```solidity
function getETHReserve(address _royaltyAddress) external view returns (uint256)
```

Gets the ETH royalty reserve balance of the royalty sales contract

_This is external view function and doesnt write to state._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |

### getERC20Reserve

```solidity
function getERC20Reserve(address _royaltyAddress, string _ticker) external view returns (uint256)
```

Gets the ERC20 royalty reserve balance for the royalty sales contract

_This is external view function and doesnt write to state._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _ticker | string | The ticker of the token |

### getPendingRoyalty

```solidity
function getPendingRoyalty(address _royaltyAddress, string _ticker) external view returns (uint256)
```

Gets the royalty pending balance for the royalty sales contract

_This is external view function and doesnt write to state._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _ticker | string | The ticker of the token |

### getRoyaltyPaid

```solidity
function getRoyaltyPaid(address _royaltyAddress, string _ticker) external view returns (uint256)
```

returns the amount of royalty that has paid to the royalty sales contract

_This is external view function and doesnt write to state._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty sales contract |
| _ticker | string | The ticker of the token |

### getTokenAddress

```solidity
function getTokenAddress(string _ticker) external view returns (address)
```

gets the royalty address of the token by ticker

_This is external view function and doesnt write to state._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _ticker | string | The ticker of the token |

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

gets the picardy automation registrar address

_This is external view function and doesnt write to state._

### checkTickerExist

```solidity
function checkTickerExist(string _ticker) external view returns (bool)
```

checks that the ticker is registered

## IPayMaster

### getERC20Reserve

```solidity
function getERC20Reserve(address _royaltyAddress, string _ticker) external view returns (uint256)
```

### getETHReserve

```solidity
function getETHReserve(address _royaltyAddress) external view returns (uint256)
```

### getRoyaltyPaid

```solidity
function getRoyaltyPaid(address _royaltyAddress, string _ticker) external view returns (uint256)
```

### getPendingRoyalty

```solidity
function getPendingRoyalty(address _royaltyAddress, string _ticker) external view returns (uint256)
```

### addETHReserve

```solidity
function addETHReserve(address _royaltyAddress, uint256 _amount) external payable
```

### addERC20Reserve

```solidity
function addERC20Reserve(address _royaltyAddress, string _ticker, uint256 _amount) external
```

### sendPayment

```solidity
function sendPayment(address _royaltyAddress, string _ticker, uint256 _amount) external returns (bool)
```

### checkTickerExist

```solidity
function checkTickerExist(string _ticker) external view returns (bool)
```

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

### addRoyaltyData

```solidity
function addRoyaltyData(address _adapter, address _royaltyAddress, uint256 royaltyType, string ticker) external
```

### removeRoyaltyData

```solidity
function removeRoyaltyData(address _adapter, address _royaltyAddress) external
```

### getTokenAddress

```solidity
function getTokenAddress(string _ticker) external view returns (address)
```

### refundPending

```solidity
function refundPending(address _royaltyAddress, string _ticker, uint256 _amount) external
```

### withdrawReserve

```solidity
function withdrawReserve(address _royaltyAddress, string _ticker, uint256 _amount) external
```

### removeToken

```solidity
function removeToken(string _ticker) external
```

### addRegAddress

```solidity
function addRegAddress(address _picardyReg) external
```

### addToken

```solidity
function addToken(string _ticker, address _tokenAddress) external
```

## RoyaltyAdapterV2

### OnlyLink

```solidity
error OnlyLink()
```

### RoyaltyData

```solidity
event RoyaltyData(bytes32 requestId, uint256 value, address royaltySaleAddress)
```

### payMaster

```solidity
address payMaster
```

### picardyReg

```solidity
address picardyReg
```

### picardyHub

```solidity
address picardyHub
```

### linkAddress

```solidity
address linkAddress
```

### saleExists

```solidity
mapping(address => bool) saleExists
```

### linkBalance

```solidity
mapping(address => uint256) linkBalance
```

### LINK

```solidity
contract LinkTokenInterface LINK
```

### i_royaltyReg

```solidity
contract IRoyaltyAutomationRegistrarV2 i_royaltyReg
```

### onlyLINK

```solidity
modifier onlyLINK()
```

### constructor

```solidity
constructor(address _linkToken, address _payMaster, address _picardyHub) public
```

### addPicardyReg

```solidity
function addPicardyReg(address _picardyReg) external
```

This function is called by the Picardy Hub Admin to add the picardyReg address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _picardyReg | address | The address of the Picardy Royalty Automation Registrar |

### addValidSaleAddress

```solidity
function addValidSaleAddress(address _royaltySaleAddress) external
```

this function is called on registration of automation

_this function should only be called by the picardy automation Registrar_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltySaleAddress | address | The address of the royalty sale contract |

### checkIsValidSaleAddress

```solidity
function checkIsValidSaleAddress(address _royaltySaleAddress) external view returns (bool)
```

this function is called to check the validity of the royalty sale address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltySaleAddress | address | The address of the royalty sale contract |

### requestRoyaltyAmount

```solidity
function requestRoyaltyAmount(address _royaltySaleAddress, address _oracle, uint256 _royaltyType, string _jobId) external
```

this function is called by a valid royalty sale contract to request the royalty amount to be sent to the paymaster

_this function should only be called by a registered royalty sale contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltySaleAddress | address | The address of the royalty sale contract |
| _oracle | address | The address of the oracle |
| _royaltyType | uint256 | The type of royalty sale |
| _jobId | string | The job id of the oracle |

### fulfillrequestRoyaltyAmount

```solidity
function fulfillrequestRoyaltyAmount(bytes32 _requestId, uint256 amount, address _royaltySaleAddress) public
```

this function is called by the oracle to fulfill the request and send the royalty amount to the paymaster

_this function should only be called by the oracle_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _requestId | bytes32 | The request id from the node. |
| amount | uint256 | The amount of royalty to be sent to the paymaster |
| _royaltySaleAddress | address | The address of the royalty sale contract |

### onTokenTransfer

```solidity
function onTokenTransfer(address _sender, uint256 _amount, bytes _data) external
```

this is an implimentation of the ERC677 callback function for LINK token

_this function should only be called by the LINK token contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _sender | address | The address of the sender. This should be the picardy automation registrar. |
| _amount | uint256 | The amount of LINK sent. |
| _data | bytes | The data sent with the transaction. |

### getRoyaltyLinkBalance

```solidity
function getRoyaltyLinkBalance(address _royaltySaleAddress) external view returns (uint256)
```

this function gets the link token balance of the royalty sale contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltySaleAddress | address | The address of the royalty sale contract |

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

this function is called to get the picardy automation registrar address

### contractBalances

```solidity
function contractBalances() public view returns (uint256 eth, uint256 link)
```

### getPayMaster

```solidity
function getPayMaster() external view returns (address)
```

### getChainlinkToken

```solidity
function getChainlinkToken() external view returns (address)
```

### withdrawLink

```solidity
function withdrawLink() external
```

this function is called to withdraw LINK from the contract and should be called only by the picardy hub admin

### adminWithdrawLink

```solidity
function adminWithdrawLink(address _royaltyAddress) external
```

this function is called by the royalty admin to take out link balance from the contract

_this function should only be called by the royalty admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | The address of the royalty contract |

### withdrawBalance

```solidity
function withdrawBalance() external
```

this function is called to withdraw ETH from the contract and should be called only by the picardy hub admin

### updateOraclePayment

```solidity
function updateOraclePayment(uint256 _newPayment) external
```

ths function is called to update the oracle payment and should be called only by the picardy hub admin

### cancelRequest

```solidity
function cancelRequest(bytes32 _requestId, uint256 _payment, bytes4 _callbackFunctionId, uint256 _expiration) public
```

### receive

```solidity
receive() external payable
```

## IRoyaltyAdapterV2

### requestRoyaltyAmount

```solidity
function requestRoyaltyAmount(address _royaltySaleAddress, address _oracle, uint256 _royaltyType, string _jobId) external
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 _amount) external
```

### checkIsValidSaleAddress

```solidity
function checkIsValidSaleAddress(address _royaltySaleAddress) external view returns (bool)
```

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

### getPayMaster

```solidity
function getPayMaster() external view returns (address)
```

### addValidSaleAddress

```solidity
function addValidSaleAddress(address _royaltySaleAddress) external
```

### getRoyaltyLinkBalance

```solidity
function getRoyaltyLinkBalance(address _royaltySaleAddress) external view returns (uint256)
```

### adminWithdrawLink

```solidity
function adminWithdrawLink(address _royaltyAddress) external
```

### withdrawBalance

```solidity
function withdrawBalance() external
```

### updateOraclePayment

```solidity
function updateOraclePayment(uint256 _newPayment) external
```

## KeeperRegistrarInterface

### register

```solidity
function register(string name, bytes encryptedEmail, address upkeepContract, uint32 gasLimit, address adminAddress, bytes checkData, uint96 amount, uint8 source, address sender) external
```

## RoyaltyAutomationRegistrarV2

### AutomationRegistered

```solidity
event AutomationRegistered(address royaltyAddress)
```

_Picardy RoyaltyAutomationRegistrarV2 
        manages the royalty automation and inherits 
        chainlink KeeperRegistrarInterface._

### AutomationFunded

```solidity
event AutomationFunded(address royaltyAddress, uint96 amount)
```

### AutomationCancled

```solidity
event AutomationCancled(address royaltyAddress)
```

### AutomationRestarted

```solidity
event AutomationRestarted(address royaltyAddress)
```

### AutomationToggled

```solidity
event AutomationToggled(address royaltyAddress)
```

### RegisteredDetails

```solidity
struct RegisteredDetails {
  address royaltyAddress;
  address adapterAddress;
  address adminAddress;
  uint256 upkeepId;
  uint256 royaltyType;
}
```

### RegistrationDetails

```solidity
struct RegistrationDetails {
  string name;
  string ticker;
  string email;
  string jobId;
  address oracle;
  address royaltyAddress;
  address adminAddress;
  uint256 royaltyType;
  uint256 updateInterval;
  uint32 gasLimit;
  uint96 amount;
}
```

### PayloadDetails

```solidity
struct PayloadDetails {
  string name;
  bytes encryptedEmail;
  address royaltyAddress;
  uint32 gasLimit;
  address adminAddress;
  bytes checkData;
  uint96 amount;
  uint8 source;
}
```

### registry

```solidity
address registry
```

### link

```solidity
address link
```

### registrar

```solidity
address registrar
```

### adapter

```solidity
address adapter
```

### picardyHub

```solidity
address picardyHub
```

### payMaster

```solidity
address payMaster
```

### registerSig

```solidity
bytes4 registerSig
```

### registeredDetails

```solidity
mapping(address => struct RoyaltyAutomationRegistrarV2.RegisteredDetails) registeredDetails
```

### hasReg

```solidity
mapping(address => bool) hasReg
```

### i_payMaster

```solidity
contract IPayMaster i_payMaster
```

### i_link

```solidity
contract LinkTokenInterface i_link
```

### i_registry

```solidity
contract AutomationRegistryInterface i_registry
```

### constructor

```solidity
constructor(address _link, address _registrar, address _registry, address _adapter, address _picardyHub, address _payMaster) public
```

### addRoyaltyAdapter

```solidity
function addRoyaltyAdapter(address _adapterAddress) external
```

adds a new royalty adapter

_only callable by the PicardyHub admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _adapterAddress | address | address of the new royalty adapter |

### register

```solidity
function register(struct RoyaltyAutomationRegistrarV2.RegistrationDetails details) external
```

registers a new royalty contract for automation

_only callable by the royalty contract owner see (RegistrationDetails struct above for more info)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| details | struct RoyaltyAutomationRegistrarV2.RegistrationDetails | struct containing all the details for the registration |

### fundAdapterBalance

```solidity
function fundAdapterBalance(uint96 _amount, address _royaltyAddress) external
```

funds oracle fee balance on picardy royalty adapter

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint96 | amount of link to fund |
| _royaltyAddress | address | address of the royalty contract |

### fundAdapter

```solidity
function fundAdapter(uint96 _amount, address _royaltyAddress) internal
```

Internal function with extra data to fund adapter

### fundUpkeep

```solidity
function fundUpkeep(address _royaltyAddress, uint96 amount) external
```

adds funds to the upkeep automation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | address of the royalty contract |
| amount | uint96 | amount of link to fund |

### toggleAutomation

```solidity
function toggleAutomation(address _royaltyAddress) external
```

pauses automation can also be on the royalty contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | address of the royalty contract |

### cancleAutomation

```solidity
function cancleAutomation(address _royaltyAddress) external
```

cancels automation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyAddress | address | address of the royalty contract |

### updateAutomationConfig

```solidity
function updateAutomationConfig(address _link, address _registry, address _registrar) external
```

updates automation configurations(link, registry, registrar)

_can only be called by hub admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _link | address | address of the link token |
| _registry | address | address of the registry |
| _registrar | address | address of the registrar |

### updatePayMaster

```solidity
function updatePayMaster(address _payMaster) external
```

updates the paymaster address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _payMaster | address | address of the paymaster |

### getAdminAddress

```solidity
function getAdminAddress(address _royaltyAddress) external view returns (address)
```

gets royalty admin address

### getRoyaltyAdapterAddress

```solidity
function getRoyaltyAdapterAddress(address _royaltyAddress) external view returns (address)
```

gets royalty adapter address

### getRegisteredDetails

```solidity
function getRegisteredDetails(address _royaltyAddress) external view returns (struct RoyaltyAutomationRegistrarV2.RegisteredDetails)
```

returns an struct of the registered details

### _getPayload

```solidity
function _getPayload(struct RoyaltyAutomationRegistrarV2.PayloadDetails payloadDetails) internal view returns (bytes)
```

## IRoyaltyAutomationRegistrarV2

### RegistrationDetails

```solidity
struct RegistrationDetails {
  string name;
  string ticker;
  string email;
  address royaltyAddress;
  address adminAddress;
  uint256 royaltyType;
  uint256 updateInterval;
  uint32 gasLimit;
  uint96 amount;
}
```

### RegisteredDetails

```solidity
struct RegisteredDetails {
  address royaltyAddress;
  address adapterAddress;
  address adminAddress;
  uint256 upkeepId;
  uint256 royaltyType;
  string ticker;
}
```

### register

```solidity
function register(struct IRoyaltyAutomationRegistrarV2.RegistrationDetails details) external
```

### fundUpkeep

```solidity
function fundUpkeep(address royaltyAddress, uint96 amount) external
```

### toggleAutomation

```solidity
function toggleAutomation(address royaltyAddress) external
```

### addRoyaltyAdapter

```solidity
function addRoyaltyAdapter(address _adapterAddress) external
```

### fundAdapterBalance

```solidity
function fundAdapterBalance(uint96 _amount, address _royaltyAddress) external
```

### cancleAutomation

```solidity
function cancleAutomation(address _royaltyAddress) external
```

### updateAutomationConfig

```solidity
function updateAutomationConfig(address _link, address _registry, address _registrar) external
```

### updatePayMaster

```solidity
function updatePayMaster(address _payMaster) external
```

### getRoyaltyAdapterAddress

```solidity
function getRoyaltyAdapterAddress(address _royaltyAddress) external view returns (address)
```

### getAdminAddress

```solidity
function getAdminAddress(address _royaltyAddress) external view returns (address)
```

### getRoyaltyTicker

```solidity
function getRoyaltyTicker(address _royaltyAddress) external view returns (string)
```

### getRegisteredDetails

```solidity
function getRegisteredDetails(address _royaltyAddress) external view returns (struct IRoyaltyAutomationRegistrarV2.RegisteredDetails)
```

## NftRoyaltySaleFactoryV2

### nftRoyaltySaleImplementation

```solidity
address nftRoyaltySaleImplementation
```

### NftRoyaltySaleCreated

```solidity
event NftRoyaltySaleCreated(uint256 royaltySaleId, address creator, address royaltySaleAddress)
```

### RoyaltyDetailsUpdated

```solidity
event RoyaltyDetailsUpdated(uint256 percentage, address royaltyAddress)
```

### Details

```solidity
struct Details {
  uint256 maxSupply;
  uint256 maxMintAmount;
  uint256 cost;
  uint256 percentage;
  string name;
  string symbol;
  string initBaseURI;
  string creatorName;
  address creator;
}
```

### NftRoyaltyDetails

```solidity
struct NftRoyaltyDetails {
  uint256 royaltyId;
  uint256 royaltyPercentage;
  string royaltyName;
  address royaltyAddress;
}
```

### RoyaltyDetails

```solidity
struct RoyaltyDetails {
  uint256 royaltyPercentage;
  address royaltyAddress;
}
```

### royaltyDetails

```solidity
struct NftRoyaltySaleFactoryV2.RoyaltyDetails royaltyDetails
```

### nftRoyaltyDetails

```solidity
mapping(address => struct NftRoyaltySaleFactoryV2.NftRoyaltyDetails) nftRoyaltyDetails
```

### royaltySaleAddress

```solidity
mapping(string => mapping(string => address)) royaltySaleAddress
```

### picardyHub

```solidity
address picardyHub
```

### nftRoyaltyId

```solidity
uint256 nftRoyaltyId
```

### linkToken

```solidity
address linkToken
```

### constructor

```solidity
constructor(address _picardyHub, address _linkToken, address _nftRoyaltySaleImpl) public
```

### createNftRoyalty

```solidity
function createNftRoyalty(struct NftRoyaltySaleFactoryV2.Details details) external returns (address)
```

Creates a new NftRoyaltySale contract

_The NftRoyaltySale contract is created using the Clones library_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| details | struct NftRoyaltySaleFactoryV2.Details |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Address of the newly created NftRoyaltySale contract |

### updateRoyaltyDetails

```solidity
function updateRoyaltyDetails(uint256 _royaltyPercentage) external
```

Updates the royalty details

_Only the Picardy Hub Admin can call this function. Do not confuse this with the royalty percentage for the NftRoyaltySale contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyPercentage | uint256 |  |

### getLinkToken

```solidity
function getLinkToken() external view returns (address)
```

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

### getNftRoyaltySaleAddress

```solidity
function getNftRoyaltySaleAddress(string _creatorName, string _name) external view returns (address)
```

## INftRoyaltySaleFactoryV2

### Details

```solidity
struct Details {
  uint256 maxSupply;
  uint256 maxMintAmount;
  uint256 cost;
  uint256 percentage;
  string name;
  string symbol;
  string initBaseURI;
  string creatorName;
  address creator;
}
```

### createNftRoyalty

```solidity
function createNftRoyalty(struct INftRoyaltySaleFactoryV2.Details details) external returns (address)
```

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### updateRoyaltyDetails

```solidity
function updateRoyaltyDetails(uint256 _royaltyPercentage) external
```

### getLinkToken

```solidity
function getLinkToken() external view returns (address)
```

## TokenRoyaltySaleFactoryV2

### tokenRoyaltySaleImplementation

```solidity
address tokenRoyaltySaleImplementation
```

### TokenRoyaltyCreated

```solidity
event TokenRoyaltyCreated(address creator, address tokenRoyaltyAddress, uint256 royaltyId)
```

### RoyaltyDetailsUpdated

```solidity
event RoyaltyDetailsUpdated(uint256 percentage, address royaltyAddress)
```

### TokenRoyaltyDetails

```solidity
struct TokenRoyaltyDetails {
  uint256 tokenRoyaltyId;
  uint256 askAmount;
  uint256 returnPercentage;
  address tokenRoyaltyAddress;
}
```

### RoyaltyDetails

```solidity
struct RoyaltyDetails {
  uint256 royaltyPercentage;
  address royaltyAddress;
}
```

### royaltyDetails

```solidity
struct TokenRoyaltySaleFactoryV2.RoyaltyDetails royaltyDetails
```

### tokenRoyaltyDetailsMap

```solidity
mapping(address => struct TokenRoyaltySaleFactoryV2.TokenRoyaltyDetails) tokenRoyaltyDetailsMap
```

### royaltySaleAddress

```solidity
mapping(string => mapping(string => address)) royaltySaleAddress
```

### picardyHub

```solidity
address picardyHub
```

### linkToken

```solidity
address linkToken
```

### tokenRoyaltyId

```solidity
uint256 tokenRoyaltyId
```

### constructor

```solidity
constructor(address _picardyHub, address _linkToken, address _tokenRoyaltySaleImpl) public
```

### createTokenRoyalty

```solidity
function createTokenRoyalty(uint256 _askAmount, uint256 _returnPercentage, string creatorName, string name, address creator) external returns (address)
```

_Creats A ERC20 token royalty sale. contract is created using the Clones library_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _askAmount | uint256 | The total askinng amount for royalty |
| _returnPercentage | uint256 | Percentage of royalty to sell |
| creatorName | string |  |
| name | string |  |
| creator | address |  |

### updateRoyaltyDetails

```solidity
function updateRoyaltyDetails(uint256 _royaltyPercentage) external
```

the function is used to update the royalty percentage.

_only hub admin can call this function_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyPercentage | uint256 | the amount in percentage the hub takes. |

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### getTokenRoyaltyAddress

```solidity
function getTokenRoyaltyAddress(string creatorName, string name) external view returns (address)
```

### getRoyaltySaleDetails

```solidity
function getRoyaltySaleDetails(address _royaltySaleAddress) external view returns (struct TokenRoyaltySaleFactoryV2.TokenRoyaltyDetails)
```

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

### getLinkToken

```solidity
function getLinkToken() external view returns (address)
```

## ITokenRoyaltySaleFactoryV2

### createTokenRoyalty

```solidity
function createTokenRoyalty(uint256 _askAmount, uint256 _returnPercentage, string creatorName, string name) external returns (address)
```

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

### getLinkToken

```solidity
function getLinkToken() external view returns (address)
```

## NftRoyaltySaleV2

### UpkeepPerformed

```solidity
event UpkeepPerformed(uint256 time)
```

### Received

```solidity
event Received(address sender, uint256 amount)
```

### AutomationStarted

```solidity
event AutomationStarted(bool status)
```

### RoyaltySold

```solidity
event RoyaltySold(uint256 mintAmount, address buyer)
```

### RoyaltyUpdated

```solidity
event RoyaltyUpdated(uint256 royalty)
```

### WithdrawSuccess

```solidity
event WithdrawSuccess(uint256 time)
```

### RoyaltyWithdrawn

```solidity
event RoyaltyWithdrawn(uint256 amount, address holder)
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

### NftRoyaltyState

```solidity
enum NftRoyaltyState {
  OPEN,
  CLOSED
}
```

### nftRoyaltyState

```solidity
enum NftRoyaltySaleV2.NftRoyaltyState nftRoyaltyState
```

### Royalty

```solidity
struct Royalty {
  uint256 maxMintAmount;
  uint256 maxSupply;
  uint256 cost;
  uint256 percentage;
  string creatorName;
  string name;
  string initBaseURI;
  string symbol;
  address creator;
  address factoryAddress;
}
```

### royalty

```solidity
struct NftRoyaltySaleV2.Royalty royalty
```

### NodeDetails

```solidity
struct NodeDetails {
  address oracle;
  string jobId;
}
```

### nodeDetails

```solidity
struct NftRoyaltySaleV2.NodeDetails nodeDetails
```

### owner

```solidity
address owner
```

### nftRoyaltyAddress

```solidity
address nftRoyaltyAddress
```

### lastRoyaltyUpdate

```solidity
uint256 lastRoyaltyUpdate
```

### updateInterval

```solidity
uint256 updateInterval
```

### automationStarted

```solidity
bool automationStarted
```

### initialized

```solidity
bool initialized
```

### ownerWithdrawn

```solidity
bool ownerWithdrawn
```

### started

```solidity
bool started
```

### time

```solidity
uint256 time
```

### royaltyType

```solidity
uint256 royaltyType
```

### nftBalance

```solidity
mapping(address => uint256) nftBalance
```

### royaltyBalance

```solidity
mapping(address => uint256) royaltyBalance
```

### ercRoyaltyBalance

```solidity
mapping(address => mapping(address => uint256)) ercRoyaltyBalance
```

### tokenIdMap

```solidity
mapping(address => uint256[]) tokenIdMap
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### initilize

```solidity
function initilize(uint256 _maxSupply, uint256 _maxMintAmount, uint256 _cost, uint256 _percentage, string _name, string _symbol, string _initBaseURI, string _creatorName, address _creator, address _factroyAddress, address _owner) public
```

### start

```solidity
function start() external
```

this function is called by the contract owner to start the royalty sale

_this function can only be called once and it cretes the NFT contract_

### setupAutomationV2

```solidity
function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string _jobId) external
```

this function is called by Picardy Royalty Registrar when registering automation and sets up the automation

_//This function is called by picardy royalty registrar, PS: royalty adapter contract needs LINK for automation to work_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _updateInterval | uint256 | update interval for the automation |
| _royaltyAdapter | address | address of Picardy Royalty Adapter |
| _oracle | address | address of the oracle |
| _jobId | string | job id for the oracle |

### toggleAutomation

```solidity
function toggleAutomation() external
```

this function is called by the contract owner to pause automation

_this function can only be called by the contract owner and picardy royalty registrar_

### checkUpkeep

```solidity
function checkUpkeep(bytes) external view returns (bool upkeepNeeded, bytes performData)
```

This function is used by chainlink keepers to check if the requirements for upkeep are met

_this function can only be called by chainlink keepers_

### performUpkeep

```solidity
function performUpkeep(bytes) external
```

This function is used by chainlink keepers to perform upkeep if checkUpkeep() returns true

_this function can be called by anyone. checkUpkeep() parameters again to avoid unautorized call._

### buyRoyalty

```solidity
function buyRoyalty(uint256 _mintAmount, address _holder) external payable
```

This function can be called by anyone and is a payable function to buy royalty token in ETH

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _mintAmount | uint256 | amount of royalty token to be minted |
| _holder | address | address of the royalty token holder |

### updateRoyalty

```solidity
function updateRoyalty(uint256 _amount, address tokenAddress) external
```

_This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20.    
this function can only be called by the contract owner or payMaster contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint256 | amount of ERC20 tokens to be paid back to royalty holders |
| tokenAddress | address | address of the ERC20 token |

### getUpdateRoyaltyCaller

```solidity
function getUpdateRoyaltyCaller() internal view returns (address)
```

helper function that makes sure the caller is the owner or payMaster contract

### toggleRoyaltySale

```solidity
function toggleRoyaltySale() external
```

This function changes the state of the royalty sale and should only be called by the owner

### pauseTokenBase

```solidity
function pauseTokenBase() external
```

his function is used to pause the ERC721 token base contract

_this function can only be called by the contract owner_

### unPauseTokenBase

```solidity
function unPauseTokenBase() external
```

his function is used to unPause the ERC721 token base contract

_this function can only be called by the contract owner_

### getTimeLeft

```solidity
function getTimeLeft() external view returns (uint256)
```

### withdraw

```solidity
function withdraw() external
```

This function is used to withdraw the funds from the royalty sale contract and should only be called by the owner

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 _amount, address _holder) external
```

This function is used to withdraw the royalty. It can only be called by the royalty token holder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint256 | amount of royalty token to be withdrawn |
| _holder | address | address of the royalty token holder |

### withdrawERC20Royalty

```solidity
function withdrawERC20Royalty(uint256 _amount, address _holder, address _tokenAddress) external
```

This function is used to withdraw the royalty in ERC20. It can only be called by the royalty token holder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint256 | amount of royalty token to be withdrawn |
| _holder | address | address of the royalty token holder |
| _tokenAddress | address |  |

### changeUpdateInterval

```solidity
function changeUpdateInterval(uint256 _updateInterval) external
```

This function is uded to change the update interval of the royalty automation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _updateInterval | uint256 | new update interval |

### pause

```solidity
function pause() public
```

This function is used to pause the royalty sale contract and should only be called by the owner

### unpause

```solidity
function unpause() public
```

This function is used to unpause the royalty sale contract and should only be called by the owner

### transferOwnership

```solidity
function transferOwnership(address newOwner) public
```

this function is used to transfer ownership of the sale contract to a new owner and should only be called by the owner

### updateNodeDetails

```solidity
function updateNodeDetails(address _oracle, string _jobId) external
```

This function is used to change the oracle address and jobId of the chainlink node for custom job id

_this function can only be called by the contract owner. (See docs for custom automation)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _oracle | address | new oracle address |
| _jobId | string | new jobId |

### getTokensId

```solidity
function getTokensId(address _addr) external returns (uint256[])
```

### getERC20RoyaltyBalance

```solidity
function getERC20RoyaltyBalance(address _holder, address _tokenAddress) external view returns (uint256)
```

### getTokenDetails

```solidity
function getTokenDetails() external view returns (uint256, uint256, uint256, string, string, string)
```

### getCreator

```solidity
function getCreator() external view returns (address)
```

### getRoyaltyTokenAddress

```solidity
function getRoyaltyTokenAddress() external view returns (address)
```

### getOwner

```solidity
function getOwner() external view returns (address)
```

### getRoyaltyPercentage

```solidity
function getRoyaltyPercentage() external view returns (uint256)
```

### _getTokenIds

```solidity
function _getTokenIds(address addr) internal returns (uint256[])
```

### checkAutomation

```solidity
function checkAutomation() external view returns (bool)
```

### _picardyNft

```solidity
function _picardyNft() internal
```

### _update

```solidity
function _update(uint256 _amount) internal
```

### receive

```solidity
receive() external payable
```

## IPicardyNftRoyaltySaleV2

### start

```solidity
function start() external
```

starts royalty sale

### getTokenIds

```solidity
function getTokenIds(address _addr) external returns (uint256[])
```

_gets token ids of a specific address_

### getTokenDetails

```solidity
function getTokenDetails() external returns (uint256, uint256, uint256, string, string)
```

_gets token details of the caller_

### getCreator

```solidity
function getCreator() external returns (address)
```

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 _amount, address _holder) external
```

_withdraws royalty balance of the caller_

### withdrawERC20Royalty

```solidity
function withdrawERC20Royalty(uint256 _amount, address _holder, address _tokenAddress) external
```

### getRoyaltyTokenAddress

```solidity
function getRoyaltyTokenAddress() external view returns (address)
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 _amount, address tokenAddress) external
```

_updates royalty balance of token holders_

### getTokensId

```solidity
function getTokensId(address _addr) external returns (uint256[])
```

### buyRoyalty

```solidity
function buyRoyalty(uint256 _mintAmount, address _holder) external payable
```

_buys royalty tokens_

### setupAutomationV2

```solidity
function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string _jobId) external
```

### toggleAutomation

```solidity
function toggleAutomation() external
```

### toggleRoyaltySale

```solidity
function toggleRoyaltySale() external
```

### changeUpdateInterval

```solidity
function changeUpdateInterval(uint256 _updateInterval) external
```

### getERC20RoyaltyBalance

```solidity
function getERC20RoyaltyBalance(address _holder, address _tokenAddress) external view returns (uint256)
```

### getRoyaltyPercentage

```solidity
function getRoyaltyPercentage() external view returns (uint256)
```

### checkAutomation

```solidity
function checkAutomation() external view returns (bool)
```

### updateNodeDetails

```solidity
function updateNodeDetails(address _oracle, string _jobId) external
```

### getOwner

```solidity
function getOwner() external view returns (address)
```

### pause

```solidity
function pause() external
```

_pause the royalty sale contract_

### unpause

```solidity
function unpause() external
```

_unpauses the royalty sale contract_

### withdraw

```solidity
function withdraw() external
```

_withdraws all eth sent to the royalty sale contract_

## TokenRoyaltySaleV2

### RoyaltyBalanceUpdated

```solidity
event RoyaltyBalanceUpdated(uint256 time, uint256 amount)
```

### Received

```solidity
event Received(address depositor, uint256 amount)
```

### UpkeepPerformed

```solidity
event UpkeepPerformed(uint256 time)
```

### AutomationStarted

```solidity
event AutomationStarted(bool status)
```

### RoyaltyWithdrawn

```solidity
event RoyaltyWithdrawn(uint256 amount, address holder)
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

### TokenRoyaltyState

```solidity
enum TokenRoyaltyState {
  OPEN,
  CLOSED
}
```

### tokenRoyaltyState

```solidity
enum TokenRoyaltySaleV2.TokenRoyaltyState tokenRoyaltyState
```

### Royalty

```solidity
struct Royalty {
  uint256 royaltyPoolSize;
  uint256 percentage;
  uint256 royaltyPoolBalance;
  address royaltyCPToken;
  address tokenRoyaltyFactory;
  address creator;
  address[] royaltyPoolMembers;
  string creatorsName;
  string name;
}
```

### royalty

```solidity
struct TokenRoyaltySaleV2.Royalty royalty
```

### NodeDetails

```solidity
struct NodeDetails {
  address oracle;
  string jobId;
}
```

### nodeDetails

```solidity
struct TokenRoyaltySaleV2.NodeDetails nodeDetails
```

### owner

```solidity
address owner
```

### lastRoyaltyUpdate

```solidity
uint256 lastRoyaltyUpdate
```

### updateInterval

```solidity
uint256 updateInterval
```

### automationStarted

```solidity
bool automationStarted
```

### initilized

```solidity
bool initilized
```

### started

```solidity
bool started
```

### ownerWithdrawn

```solidity
bool ownerWithdrawn
```

### time

```solidity
uint256 time
```

### royaltyType

```solidity
uint256 royaltyType
```

### royaltyBalance

```solidity
mapping(address => uint256) royaltyBalance
```

### ercRoyaltyBalance

```solidity
mapping(address => mapping(address => uint256)) ercRoyaltyBalance
```

### isPoolMember

```solidity
mapping(address => bool) isPoolMember
```

### memberSize

```solidity
mapping(address => uint256) memberSize
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### initilize

```solidity
function initilize(uint256 _royaltyPoolSize, uint256 _percentage, address _tokenRoyaltyFactory, address _creator, string _creatorsName, string _name, address _owner) external
```

### start

```solidity
function start() external
```

### setupAutomationV2

```solidity
function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string _jobId) external
```

this function is called by Picardy Royalty Registrar when registering automation and sets up the automation

_This function is called by picardy royalty registrar, PS: royalty adapter contract needs LINK for automation to work_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _updateInterval | uint256 | update interval for the automation |
| _royaltyAdapter | address | address of Picardy Royalty Adapter |
| _oracle | address | address of the oracle |
| _jobId | string | job id for the oracle |

### toggleAutomation

```solidity
function toggleAutomation() external
```

this function is called by the contract owner to pause automation

_this function can only be called by the contract owner and picardy royalty registrar_

### buyRoyalty

```solidity
function buyRoyalty(address _holder) external payable
```

This function can be called by anyone and is a payable function to buy royalty token in ETH

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _holder | address | address of the royalty token holder |

### _buyRoyalty

```solidity
function _buyRoyalty(uint256 _amount, address _holder) internal
```

### checkUpkeep

```solidity
function checkUpkeep(bytes) external view returns (bool upkeepNeeded, bytes performData)
```

This function is used by chainlink keepers to check if the requirements for upkeep are met

_this function can only be called by chainlink keepers_

### performUpkeep

```solidity
function performUpkeep(bytes) external
```

This function is used by chainlink keepers to perform upkeep if checkUpkeep() returns true

_this function can be called by anyone. checkUpkeep() parameters again to avoid unautorized call._

### updateRoyalty

```solidity
function updateRoyalty(uint256 amount, address tokenAddress) external
```

_This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20.    
this function can only be called by the contract owner or payMaster contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | amount of ERC20 tokens to be paid back to royalty holders |
| tokenAddress | address | address of the ERC20 token |

### withdraw

```solidity
function withdraw() external
```

This function is used to withdraw the funds from the royalty sale contract and should only be called by the owner

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 _amount, address _holder) external
```

This function is used to withdraw the royalty. It can only be called by the royalty token holder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint256 | amount of royalty token to be withdrawn |
| _holder | address | address of the royalty token holder |

### withdrawERC20Royalty

```solidity
function withdrawERC20Royalty(uint256 _amount, address _holder, address _tokenAddress) external
```

This function is used to withdraw the royalty in ERC20. It can only be called by the royalty token holder

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _amount | uint256 | amount of royalty token to be withdrawn |
| _holder | address | address of the royalty token holder |
| _tokenAddress | address |  |

### changeRoyaltyState

```solidity
function changeRoyaltyState() external
```

This function changes the state of the royalty sale and should only be called by the owner

### changeUpdateInterval

```solidity
function changeUpdateInterval(uint256 _updateInterval) external
```

This function is uded to change the update interval of the royalty automation

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _updateInterval | uint256 | new update interval |

### transferOwnership

```solidity
function transferOwnership(address newOwner) public
```

this function is used to transfer ownership of the sale contract to a new owner and should only be called by the owner

### updateNodeDetails

```solidity
function updateNodeDetails(address _oracle, string _jobId) external
```

This function is used to change the oracle address and jobId of the chainlink node for custom job id

_this function can only be called by the contract owner. (See docs for custom automation)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _oracle | address | new oracle address |
| _jobId | string | new jobId |

### getPoolMembers

```solidity
function getPoolMembers() external view returns (address[])
```

GETTERS

### getPoolMemberCount

```solidity
function getPoolMemberCount() external view returns (uint256)
```

### getPoolSize

```solidity
function getPoolSize() external view returns (uint256)
```

### getPoolBalance

```solidity
function getPoolBalance() external view returns (uint256)
```

### getMemberPoolSize

```solidity
function getMemberPoolSize(address addr) external view returns (uint256)
```

### getRoyatyTokenAddress

```solidity
function getRoyatyTokenAddress() external view returns (address)
```

### getRoyaltyBalance

```solidity
function getRoyaltyBalance(address addr) external view returns (uint256)
```

### getERC20RoyaltyBalance

```solidity
function getERC20RoyaltyBalance(address addr, address tokenAddress) external view returns (uint256)
```

### getCreator

```solidity
function getCreator() external view returns (address)
```

### getOwner

```solidity
function getOwner() external view returns (address)
```

### getRoyaltyPercentage

```solidity
function getRoyaltyPercentage() external view returns (uint256)
```

### getRoyaltyState

```solidity
function getRoyaltyState() external view returns (uint256)
```

### getTokenDetails

```solidity
function getTokenDetails() external view returns (string, string)
```

### getTimeLeft

```solidity
function getTimeLeft() external view returns (uint256)
```

### checkAutomation

```solidity
function checkAutomation() external view returns (bool)
```

### _start

```solidity
function _start() internal
```

### _CPToken

```solidity
function _CPToken() internal
```

### _update

```solidity
function _update(uint256 amount) internal
```

This function is used to update the royalty balance of royalty token holders

_this function is called in the receive fallback function._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | amount of royalty to be distributed |

### receive

```solidity
receive() external payable
```

## IPicardyTokenRoyaltySaleV2

### start

```solidity
function start() external
```

starts the token royalty sale

### buyRoyalty

```solidity
function buyRoyalty(uint256 _amount, address _holder) external payable
```

buys royalty

### getPoolMembers

```solidity
function getPoolMembers() external view returns (address[])
```

gets the pool members

### getPoolMemberCount

```solidity
function getPoolMemberCount() external view returns (uint256)
```

gets the pool member count

### getPoolSize

```solidity
function getPoolSize() external view returns (uint256)
```

gets the pool size

### getPoolBalance

```solidity
function getPoolBalance() external view returns (uint256)
```

gets the pool balance

### getMemberPoolSize

```solidity
function getMemberPoolSize(address addr) external view returns (uint256)
```

gets the member pool size

### getRoyaltyBalance

```solidity
function getRoyaltyBalance(address addr) external view returns (uint256)
```

gets the royalty balance

### checkAutomation

```solidity
function checkAutomation() external view returns (bool)
```

### getRoyaltyPercentage

```solidity
function getRoyaltyPercentage() external view returns (uint256)
```

gets the royalty percentage

### getTokenDetails

```solidity
function getTokenDetails() external view returns (string, string)
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 amount, address tokenAddress) external
```

updates the royalty balance

### getCreator

```solidity
function getCreator() external view returns (address)
```

### getOwner

```solidity
function getOwner() external view returns (address)
```

### withdraw

```solidity
function withdraw() external
```

withdraws the royalty contract balance

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 _amount, address _holder) external
```

withdraws the royalty balance

### withdrawERC20Royalty

```solidity
function withdrawERC20Royalty(uint256 _amount, address _holder, address _tokenAddress) external
```

### setupAutomationV2

```solidity
function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string _jobId) external
```

### toggleAutomation

```solidity
function toggleAutomation() external
```

## PayMaster

### PaymentPending

```solidity
event PaymentPending(address royaltyAddress, string ticker, uint256 amount)
```

### PendingRoyaltyRefunded

```solidity
event PendingRoyaltyRefunded(address royaltyAddress, string ticker, uint256 amount)
```

### RoyaltyPaymentSent

```solidity
event RoyaltyPaymentSent(address royaltyAddress, string ticker, uint256 amount)
```

### picardyHub

```solidity
contract IPicardyHub picardyHub
```

### royaltyReserve

```solidity
mapping(address => mapping(address => mapping(string => uint256))) royaltyReserve
```

### royaltyPending

```solidity
mapping(address => mapping(address => mapping(string => uint256))) royaltyPending
```

### royaltyPaid

```solidity
mapping(address => mapping(address => mapping(string => uint256))) royaltyPaid
```

### isRegistered

```solidity
mapping(address => mapping(address => bool)) isRegistered
```

### royaltyData

```solidity
mapping(address => struct PayMaster.RoyaltyData) royaltyData
```

### tokenAddress

```solidity
mapping(string => address) tokenAddress
```

### tickerExist

```solidity
mapping(string => bool) tickerExist
```

### RoyaltyData

```solidity
struct RoyaltyData {
  address adapter;
  address payable royaltyAddress;
  uint256 royaltyType;
}
```

### constructor

```solidity
constructor(address _picardyHub) public
```

### addToken

```solidity
function addToken(string _ticker, address _tokenAddress) public
```

### addRegAddress

```solidity
function addRegAddress(address _picardyReg) external
```

### removeToken

```solidity
function removeToken(string _ticker) public
```

### addRoyaltyData

```solidity
function addRoyaltyData(address _adapter, address _royaltyAddress, uint256 royaltyType) public
```

### removeRoyaltyData

```solidity
function removeRoyaltyData(address _adapter, address _royaltyAddress) public
```

### addETHReserve

```solidity
function addETHReserve(address _adapter, uint256 _amount) public payable
```

### addERC20Reserve

```solidity
function addERC20Reserve(address _adapter, string _ticker, uint256 _amount) public
```

### sendPayment

```solidity
function sendPayment(address _adapter, string _ticker, uint256 _amount) public
```

### refundPending

```solidity
function refundPending(address _adapter, string _ticker, uint256 _amount) public
```

### getRoyaltyReserve

```solidity
function getRoyaltyReserve(address _adapter, string _ticker) public view returns (uint256)
```

### getRoyaltyPending

```solidity
function getRoyaltyPending(address _adapter, string _ticker) public view returns (uint256)
```

### getRoyaltyPaid

```solidity
function getRoyaltyPaid(address _adapter, string _ticker) public view returns (uint256)
```

### getTokenAddress

```solidity
function getTokenAddress(string _ticker) public view returns (address)
```

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

### checkTickerExist

```solidity
function checkTickerExist(string _ticker) external view returns (bool)
```

## IPayMaster

### getRoyaltyReserve

```solidity
function getRoyaltyReserve(address _adapter, string _ticker) external view returns (uint256)
```

### getRoyaltyPending

```solidity
function getRoyaltyPending(address _adapter, string _ticker) external view returns (uint256)
```

### getRoyaltyPaid

```solidity
function getRoyaltyPaid(address _adapter, string _ticker) external view returns (uint256)
```

### getTokenAddress

```solidity
function getTokenAddress(string _ticker) external view returns (address)
```

### addRoyaltyReserve

```solidity
function addRoyaltyReserve(address _adapter, string _ticker, uint256 _amount) external payable
```

### addRoyaltyData

```solidity
function addRoyaltyData(address _adapter, address _royaltyAddress, uint256 royaltyType) external
```

### removeRoyaltyData

```solidity
function removeRoyaltyData(address _adapter, address _royaltyAddress) external
```

### sendPayment

```solidity
function sendPayment(address _adapter, string _ticker, uint256 _amount) external
```

### checkTickerExist

```solidity
function checkTickerExist(string _ticker) external view returns (bool)
```

## RoyaltyAdapter

### RoyaltyData

```solidity
event RoyaltyData(bytes32 requestId, uint256 value)
```

### lastRetrievedInfo

```solidity
string lastRetrievedInfo
```

### owner

```solidity
address owner
```

### oracle

```solidity
address oracle
```

### payMaster

```solidity
address payMaster
```

### royaltySaleAddress

```solidity
address royaltySaleAddress
```

### picardyReg

```solidity
address picardyReg
```

### jobId

```solidity
string jobId
```

### initialized

```solidity
bool initialized
```

### ticker

```solidity
string ticker
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### initilize

```solidity
function initilize(address _linkToken, address _oracle, string _jobId, string _ticker, address _royaltySaleAddress, address _owner, address _payMaster, address _picardyReg) public
```

### updateTicker

```solidity
function updateTicker(string _ticker) public
```

### requestRoyaltyAmount

```solidity
function requestRoyaltyAmount() public
```

### fulfillrequestRoyaltyAmount

```solidity
function fulfillrequestRoyaltyAmount(bytes32 _requestId, uint256 amount) public
```

### getTickerAddress

```solidity
function getTickerAddress() public view returns (address)
```

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

### contractBalances

```solidity
function contractBalances() public view returns (uint256 eth, uint256 link)
```

### initilizeAdapter

```solidity
function initilizeAdapter(address _oracle, string _jobId) external
```

### getRoyaltySaleAddress

```solidity
function getRoyaltySaleAddress() public view returns (address)
```

### getPayMaster

```solidity
function getPayMaster() external view returns (address)
```

### getChainlinkToken

```solidity
function getChainlinkToken() public view returns (address)
```

### withdrawLink

```solidity
function withdrawLink() public
```

### withdrawBalance

```solidity
function withdrawBalance() public
```

### cancelRequest

```solidity
function cancelRequest(bytes32 _requestId, uint256 _payment, bytes4 _callbackFunctionId, uint256 _expiration) public
```

### receive

```solidity
receive() external payable
```

## IRoyaltyAdapter

### requestRoyaltyAmount

```solidity
function requestRoyaltyAmount() external
```

### getRoyaltySaleAddress

```solidity
function getRoyaltySaleAddress() external view returns (address)
```

### getTickerAddress

```solidity
function getTickerAddress() external view returns (address)
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 _amount) external
```

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

### getPayMaster

```solidity
function getPayMaster() external view returns (address)
```

## KeeperRegistrarInterface

### register

```solidity
function register(string name, bytes encryptedEmail, address upkeepContract, uint32 gasLimit, address adminAddress, bytes checkData, uint96 amount, uint8 source, address sender) external
```

## RoyaltyAutomationRegistrar

### AutomationRegistered

```solidity
event AutomationRegistered(address royaltyAddress)
```

### AutomationFunded

```solidity
event AutomationFunded(address royaltyAddress, uint96 amount)
```

### AutomationCancled

```solidity
event AutomationCancled(address royaltyAddress)
```

### AutomationRestarted

```solidity
event AutomationRestarted(address royaltyAddress)
```

### AutomationToggled

```solidity
event AutomationToggled(address royaltyAddress)
```

### RegisteredDetails

```solidity
struct RegisteredDetails {
  address royaltyAddress;
  address adapterAddress;
  address adminAddress;
  uint256 upkeepId;
  uint256 royaltyType;
}
```

### RegistrationDetails

```solidity
struct RegistrationDetails {
  string name;
  string ticker;
  string email;
  address royaltyAddress;
  address adminAddress;
  uint256 royaltyType;
  uint256 updateInterval;
  uint32 gasLimit;
  uint96 amount;
}
```

### PayloadDetails

```solidity
struct PayloadDetails {
  string name;
  bytes encryptedEmail;
  address royaltyAddress;
  uint32 gasLimit;
  address adminAddress;
  bytes checkData;
  uint96 amount;
  uint8 source;
}
```

### registry

```solidity
address registry
```

### link

```solidity
address link
```

### registrar

```solidity
address registrar
```

### adapterFactory

```solidity
address adapterFactory
```

### picardyHub

```solidity
address picardyHub
```

### payMaster

```solidity
address payMaster
```

### registerSig

```solidity
bytes4 registerSig
```

### registeredDetails

```solidity
mapping(address => struct RoyaltyAutomationRegistrar.RegisteredDetails) registeredDetails
```

### hasReg

```solidity
mapping(address => bool) hasReg
```

### i_payMaster

```solidity
contract IPayMaster i_payMaster
```

### i_link

```solidity
contract LinkTokenInterface i_link
```

### i_registry

```solidity
contract AutomationRegistryInterface i_registry
```

### constructor

```solidity
constructor(address _link, address _registrar, address _registry, address _adapterFactory, address _picardyHub, address _payMaster) public
```

### register

```solidity
function register(struct RoyaltyAutomationRegistrar.RegistrationDetails details) external
```

### fundAutomation

```solidity
function fundAutomation(address royaltyAddress, uint96 amount) external
```

### toggleAutomation

```solidity
function toggleAutomation(address royaltyAddress) external
```

### cancleAutomation

```solidity
function cancleAutomation(address royaltyAddress) external
```

### updateAutomationConfig

```solidity
function updateAutomationConfig(address _link, address _registry, address _registrar) external
```

### updatePayMaster

```solidity
function updatePayMaster(address _payMaster) external
```

### getRoyaltyAdapterAddress

```solidity
function getRoyaltyAdapterAddress(address _royaltyAddress) external view returns (address)
```

### getRegisteredDetails

```solidity
function getRegisteredDetails(address _royaltyAddress) external view returns (struct RoyaltyAutomationRegistrar.RegisteredDetails)
```

### _getPayload

```solidity
function _getPayload(struct RoyaltyAutomationRegistrar.PayloadDetails payloadDetails) internal view returns (bytes)
```

## IRoyaltyAutomationRegistrar

### RegistrationDetails

```solidity
struct RegistrationDetails {
  string name;
  string ticker;
  string email;
  address royaltyAddress;
  address adminAddress;
  uint256 royaltyType;
  uint256 updateInterval;
  uint32 gasLimit;
  uint96 amount;
}
```

### RegisteredDetails

```solidity
struct RegisteredDetails {
  address royaltyAddress;
  address adapterAddress;
  address adminAddress;
  uint256 upkeepId;
}
```

### register

```solidity
function register(struct IRoyaltyAutomationRegistrar.RegistrationDetails details) external
```

### fundAutomation

```solidity
function fundAutomation(address royaltyAddress, uint96 amount) external
```

### cancleAutomation

```solidity
function cancleAutomation(address royaltyAddress, uint256 _royaltyType) external
```

### resetAutomation

```solidity
function resetAutomation(struct IRoyaltyAutomationRegistrar.RegistrationDetails details) external
```

### getRegisteredDetails

```solidity
function getRegisteredDetails(address royaltyAddress) external view returns (struct IRoyaltyAutomationRegistrar.RegisteredDetails)
```

### toggleAutomation

```solidity
function toggleAutomation(address royaltyAddress) external
```

### getRoyaltyAdapterAddress

```solidity
function getRoyaltyAdapterAddress(address _royaltyAddress) external view returns (address)
```

## TokenRoyaltyAdapter

### RoyaltyData

```solidity
event RoyaltyData(bytes32 requestId, uint256 value)
```

### owner

```solidity
address owner
```

### oracle

```solidity
address oracle
```

### royaltySaleAddress

```solidity
address royaltySaleAddress
```

### payMaster

```solidity
address payMaster
```

### picardyReg

```solidity
address picardyReg
```

### jobId

```solidity
string jobId
```

### ticker

```solidity
string ticker
```

### initialized

```solidity
bool initialized
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### initilize

```solidity
function initilize(address _linkToken, address _oracle, string _jobId, string _ticker, address _royaltySaleAddress, address _owner, address _payMaster, address _picardyReg) public
```

### requestRoyaltyAmount

```solidity
function requestRoyaltyAmount() public
```

### fulfillrequestRoyaltyAmount

```solidity
function fulfillrequestRoyaltyAmount(bytes32 _requestId, uint256 amount) public
```

### getTickerAddress

```solidity
function getTickerAddress() public view returns (address)
```

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

### contractBalances

```solidity
function contractBalances() public view returns (uint256 eth, uint256 link)
```

### initilizeAdapter

```solidity
function initilizeAdapter(address _oracle, string _jobId) external
```

### getChainlinkToken

```solidity
function getChainlinkToken() public view returns (address)
```

### getPayMaster

```solidity
function getPayMaster() external view returns (address)
```

### getRoyaltySaleAddress

```solidity
function getRoyaltySaleAddress() public view returns (address)
```

### withdrawLink

```solidity
function withdrawLink() public
```

### withdrawBalance

```solidity
function withdrawBalance() public
```

### cancelRequest

```solidity
function cancelRequest(bytes32 _requestId, uint256 _payment, bytes4 _callbackFunctionId, uint256 _expiration) public
```

### receive

```solidity
receive() external payable
```

## ITokenRoyaltyAdapter

### requestRoyaltyAmount

```solidity
function requestRoyaltyAmount() external
```

### getRoyaltySaleAddress

```solidity
function getRoyaltySaleAddress() external view returns (address)
```

### getTickerAddress

```solidity
function getTickerAddress() external view returns (address)
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 _amount) external
```

### getPicardyReg

```solidity
function getPicardyReg() external view returns (address)
```

### getPayMaster

```solidity
function getPayMaster() external view returns (address)
```

## NftRoyaltySaleFactory

### nftRoyaltySaleImplementation

```solidity
address nftRoyaltySaleImplementation
```

### NftRoyaltySaleCreated

```solidity
event NftRoyaltySaleCreated(uint256 royaltySaleId, address creator, address royaltySaleAddress)
```

### RoyaltyDetailsUpdated

```solidity
event RoyaltyDetailsUpdated(uint256 percentage, address royaltyAddress)
```

### Details

```solidity
struct Details {
  uint256 maxSupply;
  uint256 maxMintAmount;
  uint256 cost;
  uint256 percentage;
  string name;
  string symbol;
  string initBaseURI;
  string creatorName;
  address creator;
}
```

### NftRoyaltyDetails

```solidity
struct NftRoyaltyDetails {
  uint256 royaltyId;
  uint256 royaltyPercentage;
  string royaltyName;
  address royaltyAddress;
}
```

### RoyaltyDetails

```solidity
struct RoyaltyDetails {
  uint256 royaltyPercentage;
  address royaltyAddress;
}
```

### royaltyDetails

```solidity
struct NftRoyaltySaleFactory.RoyaltyDetails royaltyDetails
```

### nftRoyaltyDetails

```solidity
mapping(address => struct NftRoyaltySaleFactory.NftRoyaltyDetails) nftRoyaltyDetails
```

### royaltySaleAddress

```solidity
mapping(string => mapping(string => address)) royaltySaleAddress
```

### picardyHub

```solidity
address picardyHub
```

### nftRoyaltyId

```solidity
uint256 nftRoyaltyId
```

### linkToken

```solidity
address linkToken
```

### constructor

```solidity
constructor(address _picardyHub, address _linkToken, address _nftRoyaltySaleImpl) public
```

### createNftRoyalty

```solidity
function createNftRoyalty(struct NftRoyaltySaleFactory.Details details) external returns (address)
```

### updateRoyaltyDetails

```solidity
function updateRoyaltyDetails(uint256 _royaltyPercentage) external
```

### addRoyaltyUri

```solidity
function addRoyaltyUri(address _royaltyAddress, string _royaltyUri) external
```

### getRoyaltyUri

```solidity
function getRoyaltyUri(address _royaltyAddress) external view returns (string)
```

### getLinkToken

```solidity
function getLinkToken() external view returns (address)
```

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

### getNftRoyaltySaleAddress

```solidity
function getNftRoyaltySaleAddress(string _creatorName, string _name) external view returns (address)
```

## INftRoyaltySaleFactory

### Details

```solidity
struct Details {
  uint256 maxSupply;
  uint256 maxMintAmount;
  uint256 cost;
  uint256 percentage;
  string name;
  string symbol;
  string initBaseURI;
  string creatorName;
  address creator;
}
```

### createNftRoyalty

```solidity
function createNftRoyalty(struct INftRoyaltySaleFactory.Details details) external returns (address)
```

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### updateRoyaltyDetails

```solidity
function updateRoyaltyDetails(uint256 _royaltyPercentage) external
```

### getRoyaltyUri

```solidity
function getRoyaltyUri(address _royaltyAddress) external view returns (string)
```

### getLinkToken

```solidity
function getLinkToken() external view returns (address)
```

## RoyaltyAdapterFactory

### AdapterCreated

```solidity
event AdapterCreated(address adapterAddress, uint256 adapterId)
```

### nftRoyaltyAdapterImplimentation

```solidity
address nftRoyaltyAdapterImplimentation
```

### tokenRoyaltyAdapterImplimentation

```solidity
address tokenRoyaltyAdapterImplimentation
```

### picardyHub

```solidity
address picardyHub
```

### payMaster

```solidity
address payMaster
```

### jobId

```solidity
string jobId
```

### adapterId

```solidity
uint256 adapterId
```

### AdapterDetails

```solidity
struct AdapterDetails {
  address adapterAddress;
  uint256 adapterId;
}
```

### adapterDetails

```solidity
mapping(address => struct RoyaltyAdapterFactory.AdapterDetails) adapterDetails
```

### adapterAddress

```solidity
mapping(uint256 => address) adapterAddress
```

### adapterExixt

```solidity
mapping(address => bool) adapterExixt
```

### isHubAdmin

```solidity
modifier isHubAdmin()
```

### constructor

```solidity
constructor(address _picardyHub, address _linkToken, address _oracle, string _jobId, address _nftRoyaltyAdapterImp, address _tokenRoyaltyAdapterImpl, address _payMaster) public
```

### addPicardyReg

```solidity
function addPicardyReg(address _picardyReg) external
```

### createAdapter

```solidity
function createAdapter(address _royaltySaleAddress, uint256 royaltyType, string _ticker) external returns (address)
```

### changeOracle

```solidity
function changeOracle(address _oracle) external
```

### changeLinkToken

```solidity
function changeLinkToken(address _linkToken) external
```

### changeJobId

```solidity
function changeJobId(string _jobId) external
```

### _isHubAdmin

```solidity
function _isHubAdmin() internal
```

### getAdapterDetails

```solidity
function getAdapterDetails(address _royaltySaleAddress) external view returns (struct RoyaltyAdapterFactory.AdapterDetails _adapterDetails)
```

### getPayMaster

```solidity
function getPayMaster() external view returns (address)
```

## IRoyaltyAdapterFactory

### AdapterDetails

```solidity
struct AdapterDetails {
  address adapterAddress;
  uint256 adapterId;
}
```

### changeOracle

```solidity
function changeOracle(address _oracle) external
```

### changeLinkToken

```solidity
function changeLinkToken(address _linkToken) external
```

### changeJobId

```solidity
function changeJobId(string _jobId) external
```

### getPayMaster

```solidity
function getPayMaster() external view returns (address)
```

### getAdapterDetails

```solidity
function getAdapterDetails(address _royaltySaleAddress) external view returns (struct IRoyaltyAdapterFactory.AdapterDetails _adapterDetails)
```

### createAdapter

```solidity
function createAdapter(address _royaltySaleAddress, uint256 royaltyType, string _ticker) external returns (address)
```

## TokenRoyaltySaleFactory

Used to create token royalty sale contracts.

### tokenRoyaltySaleImplementation

```solidity
address tokenRoyaltySaleImplementation
```

### TokenRoyaltyCreated

```solidity
event TokenRoyaltyCreated(address creator, address tokenRoyaltyAddress, uint256 royaltyId)
```

### RoyaltyDetailsUpdated

```solidity
event RoyaltyDetailsUpdated(uint256 percentage, address royaltyAddress)
```

### TokenRoyaltyDetails

```solidity
struct TokenRoyaltyDetails {
  uint256 tokenRoyaltyId;
  uint256 askAmount;
  uint256 returnPercentage;
  address tokenRoyaltyAddress;
}
```

### RoyaltyDetails

```solidity
struct RoyaltyDetails {
  uint256 royaltyPercentage;
  address royaltyAddress;
}
```

### royaltyDetails

```solidity
struct TokenRoyaltySaleFactory.RoyaltyDetails royaltyDetails
```

### tokenRoyaltyDetailsMap

```solidity
mapping(address => struct TokenRoyaltySaleFactory.TokenRoyaltyDetails) tokenRoyaltyDetailsMap
```

### royaltySaleAddress

```solidity
mapping(string => mapping(string => address)) royaltySaleAddress
```

### picardyHub

```solidity
address picardyHub
```

### linkToken

```solidity
address linkToken
```

### tokenRoyaltyId

```solidity
uint256 tokenRoyaltyId
```

### constructor

```solidity
constructor(address _picardyHub, address _linkToken, address _tokenRoyaltySaleImpl) public
```

### createTokenRoyalty

```solidity
function createTokenRoyalty(uint256 _askAmount, uint256 _returnPercentage, string creatorName, string name, address creator) external returns (address)
```

_Creats A ERC20 token royalty sale contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _askAmount | uint256 | The total askinng amount for royalty |
| _returnPercentage | uint256 | Percentage of royalty to sell |
| creatorName | string |  |
| name | string |  |
| creator | address |  |

### updateRoyaltyDetails

```solidity
function updateRoyaltyDetails(uint256 _royaltyPercentage) external
```

the function is used to update the royalty percentage.

_only hub admin can call this function_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _royaltyPercentage | uint256 | the amount in percentage the hub takes. |

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### getTokenRoyaltyAddress

```solidity
function getTokenRoyaltyAddress(string creatorName, string name) external view returns (address)
```

### getRoyaltySaleDetails

```solidity
function getRoyaltySaleDetails(address _royaltySaleAddress) external view returns (struct TokenRoyaltySaleFactory.TokenRoyaltyDetails)
```

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

### getLinkToken

```solidity
function getLinkToken() external view returns (address)
```

## ITokenRoyaltySaleFactory

### createTokenRoyalty

```solidity
function createTokenRoyalty(uint256 _askAmount, uint256 _returnPercentage, string creatorName, string name) external returns (address)
```

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

### getLinkToken

```solidity
function getLinkToken() external view returns (address)
```

## NftRoyaltySale

### UpkeepPerformed

```solidity
event UpkeepPerformed(uint256 time)
```

### Received

```solidity
event Received(address sender, uint256 amount)
```

### AutomationStarted

```solidity
event AutomationStarted(bool status)
```

### RoyaltySold

```solidity
event RoyaltySold(uint256 mintAmount, address buyer)
```

### RoyaltyUpdated

```solidity
event RoyaltyUpdated(uint256 royalty)
```

### WithdrawSuccess

```solidity
event WithdrawSuccess(uint256 time)
```

### RoyaltyWithdrawn

```solidity
event RoyaltyWithdrawn(uint256 amount, address holder)
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

### NftRoyaltyState

```solidity
enum NftRoyaltyState {
  OPEN,
  CLOSED
}
```

### nftRoyaltyState

```solidity
enum NftRoyaltySale.NftRoyaltyState nftRoyaltyState
```

### Royalty

```solidity
struct Royalty {
  uint256 maxMintAmount;
  uint256 maxSupply;
  uint256 cost;
  uint256 percentage;
  string creatorName;
  string name;
  string initBaseURI;
  string symbol;
  address creator;
  address factoryAddress;
}
```

### royalty

```solidity
struct NftRoyaltySale.Royalty royalty
```

### owner

```solidity
address owner
```

### nftRoyaltyAddress

```solidity
address nftRoyaltyAddress
```

### lastRoyaltyUpdate

```solidity
uint256 lastRoyaltyUpdate
```

### updateInterval

```solidity
uint256 updateInterval
```

### automationStarted

```solidity
bool automationStarted
```

### initialized

```solidity
bool initialized
```

### ownerWithdrawn

```solidity
bool ownerWithdrawn
```

### time

```solidity
uint256 time
```

### nftBalance

```solidity
mapping(address => uint256) nftBalance
```

### royaltyBalance

```solidity
mapping(address => uint256) royaltyBalance
```

### ercRoyaltyBalance

```solidity
mapping(address => mapping(address => uint256)) ercRoyaltyBalance
```

### tokenIdMap

```solidity
mapping(address => uint256[]) tokenIdMap
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### initilize

```solidity
function initilize(uint256 _maxSupply, uint256 _maxMintAmount, uint256 _cost, uint256 _percentage, string _name, string _symbol, string _initBaseURI, string _creatorName, address _creator, address _factroyAddress, address _owner) public
```

### start

```solidity
function start() external
```

### setupAutomation

```solidity
function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external
```

### setupAutomationV2

```solidity
function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter) external
```

### toggleAutomation

```solidity
function toggleAutomation() external
```

### checkUpkeep

```solidity
function checkUpkeep(bytes) external view returns (bool upkeepNeeded, bytes performData)
```

### performUpkeep

```solidity
function performUpkeep(bytes) external
```

### buyRoyalty

```solidity
function buyRoyalty(uint256 _mintAmount, address _holder) external payable
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 _amount, address tokenAddress) external
```

_This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20._

### toggleRoyaltSale

```solidity
function toggleRoyaltSale() external
```

### pauseTokenBase

```solidity
function pauseTokenBase() external
```

### unPauseTokenBase

```solidity
function unPauseTokenBase() external
```

### getTimeLeft

```solidity
function getTimeLeft() external view returns (uint256)
```

### withdraw

```solidity
function withdraw() external
```

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 _amount, address _holder) external
```

### withdrawERC20Royalty

```solidity
function withdrawERC20Royalty(uint256 _amount, address _holder, address _tokenAddress) external
```

### changeUpdateInterval

```solidity
function changeUpdateInterval(uint256 _updateInterval) external
```

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### transferOwnership

```solidity
function transferOwnership(address newOwner) public
```

### getTokensId

```solidity
function getTokensId(address _addr) external returns (uint256[])
```

### getERC20RoyaltyBalance

```solidity
function getERC20RoyaltyBalance(address _holder, address _tokenAddress) external view returns (uint256)
```

### getTokenDetails

```solidity
function getTokenDetails() external view returns (uint256, uint256, uint256, string, string, string)
```

### getCreator

```solidity
function getCreator() external view returns (address)
```

### getRoyaltyTokenAddress

```solidity
function getRoyaltyTokenAddress() external view returns (address)
```

### getOwner

```solidity
function getOwner() external view returns (address)
```

### _getTokenIds

```solidity
function _getTokenIds(address addr) internal returns (uint256[])
```

### checkAutomation

```solidity
function checkAutomation() external view returns (bool)
```

### _picardyNft

```solidity
function _picardyNft() internal
```

### _update

```solidity
function _update(uint256 _amount) internal
```

### receive

```solidity
receive() external payable
```

## IPicardyNftRoyaltySale

### getTokenIds

```solidity
function getTokenIds(address _addr) external returns (uint256[])
```

_gets token ids of a specific address_

### getTokenDetails

```solidity
function getTokenDetails() external returns (uint256, uint256, uint256, string, string)
```

_gets token details of the caller_

### getCreator

```solidity
function getCreator() external returns (address)
```

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 _amount, address _holder) external
```

_withdraws royalty balance of the caller_

### withdrawERC20Royalty

```solidity
function withdrawERC20Royalty(uint256 _amount, address _holder, address _tokenAddress) external
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 _amount, address tokenAddress) external
```

_updates royalty balance of token holders_

### buyRoyalty

```solidity
function buyRoyalty(uint256 _mintAmount, address _holder) external payable
```

_buys royalty tokens_

### setupAutomation

```solidity
function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external
```

### toggleAutomation

```solidity
function toggleAutomation() external
```

### getOwner

```solidity
function getOwner() external view returns (address)
```

### pause

```solidity
function pause() external
```

_pause the royalty sale contract_

### unpause

```solidity
function unpause() external
```

_unpauses the royalty sale contract_

### withdraw

```solidity
function withdraw() external
```

_withdraws all eth sent to the royalty sale contract_

## TokenRoyaltySale

### RoyaltyBalanceUpdated

```solidity
event RoyaltyBalanceUpdated(uint256 time, uint256 amount)
```

### Received

```solidity
event Received(address depositor, uint256 amount)
```

### UpkeepPerformed

```solidity
event UpkeepPerformed(uint256 time)
```

### AutomationStarted

```solidity
event AutomationStarted(bool status)
```

### RoyaltyWithdrawn

```solidity
event RoyaltyWithdrawn(uint256 amount, address holder)
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

### TokenRoyaltyState

```solidity
enum TokenRoyaltyState {
  OPEN,
  CLOSED
}
```

### tokenRoyaltyState

```solidity
enum TokenRoyaltySale.TokenRoyaltyState tokenRoyaltyState
```

### Royalty

```solidity
struct Royalty {
  uint256 royaltyPoolSize;
  uint256 percentage;
  uint256 royaltyPoolBalance;
  address royaltyCPToken;
  address tokenRoyaltyFactory;
  address creator;
  address[] royaltyPoolMembers;
  string creatorsName;
  string name;
}
```

### royalty

```solidity
struct TokenRoyaltySale.Royalty royalty
```

### owner

```solidity
address owner
```

### lastRoyaltyUpdate

```solidity
uint256 lastRoyaltyUpdate
```

### updateInterval

```solidity
uint256 updateInterval
```

### automationStarted

```solidity
bool automationStarted
```

### initilized

```solidity
bool initilized
```

### ownerWithdrawn

```solidity
bool ownerWithdrawn
```

### time

```solidity
uint256 time
```

### royaltyBalance

```solidity
mapping(address => uint256) royaltyBalance
```

### ercRoyaltyBalance

```solidity
mapping(address => mapping(address => uint256)) ercRoyaltyBalance
```

### isPoolMember

```solidity
mapping(address => bool) isPoolMember
```

### memberSize

```solidity
mapping(address => uint256) memberSize
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### initilize

```solidity
function initilize(uint256 _royaltyPoolSize, uint256 _percentage, address _tokenRoyaltyFactory, address _creator, string _creatorsName, string _name, address _owner) external
```

### start

```solidity
function start() external
```

### setupAutomation

```solidity
function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external
```

### toggleAutomation

```solidity
function toggleAutomation() external
```

### buyRoyalty

```solidity
function buyRoyalty(address _holder) external payable
```

### _buyRoyalty

```solidity
function _buyRoyalty(uint256 _amount, address _holder) internal
```

### checkUpkeep

```solidity
function checkUpkeep(bytes) external view returns (bool upkeepNeeded, bytes performData)
```

### performUpkeep

```solidity
function performUpkeep(bytes) external
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 amount, address tokenAddress) external
```

_This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20._

### withdraw

```solidity
function withdraw() external
```

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 _amount, address _holder) external
```

### withdrawERC20Royalty

```solidity
function withdrawERC20Royalty(uint256 _amount, address _holder, address _tokenAddress) external
```

### changeRoyaltyState

```solidity
function changeRoyaltyState() external
```

### changeUpdateInterval

```solidity
function changeUpdateInterval(uint256 _updateInterval) external
```

### changeAdapter

```solidity
function changeAdapter(address _adapter) external
```

### transferOwnership

```solidity
function transferOwnership(address newOwner) public
```

### getPoolMembers

```solidity
function getPoolMembers() external view returns (address[])
```

### getPoolMemberCount

```solidity
function getPoolMemberCount() external view returns (uint256)
```

### getPoolSize

```solidity
function getPoolSize() external view returns (uint256)
```

### getPoolBalance

```solidity
function getPoolBalance() external view returns (uint256)
```

### getMemberPoolSize

```solidity
function getMemberPoolSize(address addr) external view returns (uint256)
```

### getRoyatyTokenAddress

```solidity
function getRoyatyTokenAddress() external view returns (address)
```

### getRoyaltyBalance

```solidity
function getRoyaltyBalance(address addr) external view returns (uint256)
```

### getERC20RoyaltyBalance

```solidity
function getERC20RoyaltyBalance(address addr, address tokenAddress) external view returns (uint256)
```

### getCreator

```solidity
function getCreator() external view returns (address)
```

### getOwner

```solidity
function getOwner() external view returns (address)
```

### getRoyaltyPercentage

```solidity
function getRoyaltyPercentage() external view returns (uint256)
```

### getRoyaltyState

```solidity
function getRoyaltyState() external view returns (uint256)
```

### getTokenDetails

```solidity
function getTokenDetails() external view returns (string, string)
```

### getTimeLeft

```solidity
function getTimeLeft() external view returns (uint256)
```

### checkAutomation

```solidity
function checkAutomation() external view returns (bool)
```

### _start

```solidity
function _start() internal
```

### _CPToken

```solidity
function _CPToken() internal
```

### _update

```solidity
function _update(uint256 amount) internal
```

### receive

```solidity
receive() external payable
```

## IPicardyTokenRoyaltySale

### start

```solidity
function start() external
```

starts the token royalty sale

### buyRoyalty

```solidity
function buyRoyalty(uint256 _amount, address _holder) external payable
```

buys royalty

### getPoolMembers

```solidity
function getPoolMembers() external view returns (address[])
```

gets the pool members

### getPoolMemberCount

```solidity
function getPoolMemberCount() external view returns (uint256)
```

gets the pool member count

### getPoolSize

```solidity
function getPoolSize() external view returns (uint256)
```

gets the pool size

### getPoolBalance

```solidity
function getPoolBalance() external view returns (uint256)
```

gets the pool balance

### getMemberPoolSize

```solidity
function getMemberPoolSize(address addr) external view returns (uint256)
```

gets the member pool size

### getRoyaltyBalance

```solidity
function getRoyaltyBalance(address addr) external view returns (uint256)
```

gets the royalty balance

### getRoyaltyPercentage

```solidity
function getRoyaltyPercentage() external view returns (uint256)
```

gets the royalty percentage

### getTokenDetails

```solidity
function getTokenDetails() external view returns (string, string)
```

### updateRoyalty

```solidity
function updateRoyalty(uint256 amount, address tokenAddress) external
```

updates the royalty balance

### getCreator

```solidity
function getCreator() external view returns (address)
```

### getOwner

```solidity
function getOwner() external view returns (address)
```

### withdraw

```solidity
function withdraw() external
```

withdraws the royalty contract balance

### withdrawRoyalty

```solidity
function withdrawRoyalty(uint256 _amount, address _holder) external
```

withdraws the royalty balance

### withdrawERC20Royalty

```solidity
function withdrawERC20Royalty(uint256 _amount, address _holder, address _tokenAddress) external
```

### setupAutomation

```solidity
function setupAutomation(uint256 _updateInterval, address _royaltyAdapter) external
```

### toggleAutomation

```solidity
function toggleAutomation() external
```

## MocLink

### decimal

```solidity
uint256 decimal
```

### constructor

```solidity
constructor() public
```

### mint

```solidity
function mint(uint256 _amount, address _to) public
```

## ConsumerContractV2

THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
DO NOT USE THIS CODE IN PRODUCTION.

### lastRetrievedInfo

```solidity
uint256 lastRetrievedInfo
```

### RequestForInfoFulfilled

```solidity
event RequestForInfoFulfilled(bytes32 requestId, uint256 response)
```

### constructor

```solidity
constructor() public
```

Goerli

_LINK address in Goerli network: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network_

### requestInfo

```solidity
function requestInfo(address _oracle, string _jobId, string artisteName, string songTitle) public
```

### fulfillRequestInfo

```solidity
function fulfillRequestInfo(bytes32 _requestId, uint256 amount) public
```

### contractBalances

```solidity
function contractBalances() public view returns (uint256 eth, uint256 link)
```

### getChainlinkToken

```solidity
function getChainlinkToken() public view returns (address)
```

### withdrawLink

```solidity
function withdrawLink() public
```

### withdrawBalance

```solidity
function withdrawBalance() public
```

### cancelRequest

```solidity
function cancelRequest(bytes32 _requestId, uint256 _payment, bytes4 _callbackFunctionId, uint256 _expiration) public
```

## PicardyToken

### s_maxSupply

```solidity
uint256 s_maxSupply
```

### constructor

```solidity
constructor() public
```

### _afterTokenTransfer

```solidity
function _afterTokenTransfer(address from, address to, uint256 amount) internal
```

_Move voting power when tokens are transferred.

Emits a {IVotes-DelegateVotesChanged} event._

### _mint

```solidity
function _mint(address to, uint256 amount) internal
```

### _burn

```solidity
function _burn(address account, uint256 amount) internal
```

_Snapshots the totalSupply after it has been decreased._

## ArtisteTokenFactory

### NewArtisteTokenCreated

```solidity
event NewArtisteTokenCreated(uint256 tokenId, uint256 totalAmount, address tokenAddress)
```

### RoyaltyDetailsUpdated

```solidity
event RoyaltyDetailsUpdated(uint256 percentage, address royaltyAddress)
```

### picardyHub

```solidity
address picardyHub
```

### ArtisteToken

```solidity
struct ArtisteToken {
  uint256 artisteTokenId;
  uint256 totalAmount;
  string name;
  string symbol;
  address creator;
  address artisteTokenAddress;
  uint256 cost;
}
```

### RoyaltyDetails

```solidity
struct RoyaltyDetails {
  uint256 royaltyPercentage;
  address royaltyAddress;
}
```

### royaltyDetails

```solidity
struct ArtisteTokenFactory.RoyaltyDetails royaltyDetails
```

### tokenAddressMap

```solidity
mapping(string => mapping(string => address)) tokenAddressMap
```

### artisteTokenMap

```solidity
mapping(uint256 => struct ArtisteTokenFactory.ArtisteToken) artisteTokenMap
```

### artisteTokenId

```solidity
uint256 artisteTokenId
```

### constructor

```solidity
constructor(address _picardyHub) public
```

### createArtisteToken

```solidity
function createArtisteToken(uint256 _totalAmount, string _name, string _symbol, uint256 _cost) external
```

_Creats an ERC20 contract to the caller
        @param _totalAmount The maximum suppyly of the token
        @param _name Token name 
        @param _symbol Token symbol_

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

### updateRoyaltyDetails

```solidity
function updateRoyaltyDetails(uint256 _royaltyPercentage) external
```

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### getTokenAddress

```solidity
function getTokenAddress(string _name, string _symbol) external view returns (address)
```

## IArtisteTokenFactory

### createArtisteToken

```solidity
function createArtisteToken(uint256 _totalAmount, string _name, string _symbol, uint256 _cost) external
```

### getRoyaltyDetails

```solidity
function getRoyaltyDetails() external view returns (address, uint256)
```

### getHubAddress

```solidity
function getHubAddress() external view returns (address)
```

## PicardyArtisteToken

### maxSupply

```solidity
uint256 maxSupply
```

### cost

```solidity
uint256 cost
```

### factory

```solidity
address factory
```

### constructor

```solidity
constructor(uint256 _maxSupply, string _name, string _symbol, address _creator, address _factory, uint256 _cost) public
```

### mint

```solidity
function mint(uint256 _amount, address _to) external payable
```

### withdraw

```solidity
function withdraw() external
```

