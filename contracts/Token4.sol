pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
contract Token4 is StandardToken{
  string public name = 'Token4';
  string public symbol = 'T4';
  uint8 public decimals = 2;
  uint public INITIAL_SUPPLY = 88888;
  address public _admin;

  function Token4() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    _admin = msg.sender;
  }
}
