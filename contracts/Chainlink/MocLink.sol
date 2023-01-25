// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC677.sol";
import "@chainlink/contracts/src/v0.8/interfaces/ERC677ReceiverInterface.sol";

contract MocLink is ERC20, IERC677 {

    uint decimal = 10**18;
    constructor() ERC20("Test Link", "mLINK"){
    }

    function mint(uint _amount , address _to) public {
        uint toSend = _amount*decimal;
        _mint(_to, toSend);
    }

    function transferAndCall(
    address to,
    uint256 value,
    bytes memory data
  ) external override returns (bool) {
    bool result = super.transfer(to, value);
    if (!result) return false;

    ERC677ReceiverInterface receiver = ERC677ReceiverInterface(to);
    // slither-disable-next-line unused-return
    receiver.onTokenTransfer(msg.sender, value, data);
    return true;
  }
}