// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract PicardyNftBase is ERC721Enumerable, Pausable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  
  struct Royalty {
  string baseURI;
  string  artisteName;
  uint256 maxSupply;
  uint256 maxMintAmount;
  uint saleCount;
  uint percentage;
  address[] holders;
  address saleAddress;
  }
  Royalty royalty;

  string public baseExtension = ".json";

  modifier onlySaleContract {
    _onlySaleContract();
    _;
  }

  constructor(
    uint _maxSupply,
    uint _maxMintAmount,
    uint _percentage,
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _artisteName,
    address _saleAddress,
    address _creator
  ) ERC721(_name, _symbol) {
    royalty.maxSupply = _maxSupply;
    royalty.maxMintAmount = _maxMintAmount;
    royalty.percentage = _percentage;
    royalty.baseURI = _initBaseURI;
    royalty.artisteName = _artisteName;
    royalty.saleAddress = _saleAddress;
    transferOwnership(_creator);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return royalty.baseURI;
  }

  // public

  // Holders has to approve spend before buying the token
  function buyRoyalty(uint256 _mintAmount, address addr) external onlySaleContract{
    uint256 supply = totalSupply();

    if (_tokenIds.current() == 0) {
      _tokenIds.increment();
    }

    require(_mintAmount > 0);
    require(_mintAmount <= royalty.maxMintAmount);
    require(supply + _mintAmount <= royalty.maxSupply);

    royalty.holders.push(addr);
    royalty.saleCount += _mintAmount;
   
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(addr, _tokenIds.current());
      _tokenIds.increment();
    }
  }

  function holdersTokenIds(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setMaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner{
    royalty.maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    royalty.baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause() public onlySaleContract {
        _pause();
    }

  function unpause() public onlySaleContract{
        _unpause();
    }
 
  function withdraw(address _addr) public onlyOwner{
    uint balance = address(this).balance;
    (bool os, ) = payable(_addr).call{value: balance}("");
    require(os);
  }

  function withdrawERC20(address _token, address _addr) public onlyOwner{
    IERC20 token = IERC20(_token);
    uint balance = token.balanceOf(address(this));
    (bool success) = token.transfer(_addr, balance);
    require(success, "withdrawal failed");
  }

  //override transferFrom
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    royalty.holders.push(to);
    super.transferFrom(from, to, tokenId); 
  }

  //override safeTransferFrom
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    super.safeTransferFrom(from, to, tokenId);
    royalty.holders.push(to);
  }

  function _burn( uint256 tokenId) internal override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    for (uint i = 0; i < royalty.holders.length; i++) {
      if (royalty.holders[i] == ownerOf(tokenId)) {
        royalty.holders[i] = royalty.holders[royalty.holders.length - 1];
        royalty.holders.pop();
        break;
      }
    }
    super._burn(tokenId);
  }


  function getHolders() public view returns (address[] memory){
    return royalty.holders;
  }

  function getSaleCount() public view returns (uint){
    return royalty.saleCount;
  }

  function _onlySaleContract() internal view {
    require(msg.sender == royalty.saleAddress);
  }
}

interface IPicardyNftBase {
   function getHolders() external view returns (address[] memory);
   function getSaleCount() external view returns (uint);
   function tokenURI(uint256 tokenId) external view returns (string memory);
}