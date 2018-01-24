pragma solidity ^0.4.17;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
contract Token2 is StandardToken{
  string public name = 'Token2';
  string public symbol = 'T2';
  uint8 public decimals = 2;
  uint public INITIAL_SUPPLY = 88888;
  address public _admin;
  function Token2() public{
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    _admin = msg.sender;
  }
}
