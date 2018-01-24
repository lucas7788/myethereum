pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
contract Token3 is StandardToken{
  string public name = 'Token3';
  string public symbol = 'T3';
  uint8 public decimals = 2;
  uint public INITIAL_SUPPLY = 88888;
  address public _admin;

  function Token3() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    _admin = msg.sender;
  }
}
