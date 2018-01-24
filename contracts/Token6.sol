pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
contract Token6 is StandardToken{
  string public name = 'Token6';
  string public symbol = 'T6';
  uint8 public decimals = 2;
  uint public INITIAL_SUPPLY = 88888;
  address public _admin;

  function Token6() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    _admin = msg.sender;
  }
}
