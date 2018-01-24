pragma solidity ^0.4.17;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
contract Cash is StandardToken{
  string public name = 'Cash';
  string public symbol = 'C';
  uint8 public decimals = 2;
  uint public INITIAL_SUPPLY = 8888888;
  uint256 public _cashPrice;//以太币和cash的兑换关系
  address public _admin;

  function Cash(uint cashPrice) public{
    balances[msg.sender] = INITIAL_SUPPLY;
    _admin = msg.sender;
    _cashPrice = cashPrice;
    totalSupply = INITIAL_SUPPLY;
  }

  function tokensSold() view public returns (uint) {
    return (INITIAL_SUPPLY - balanceOf(_admin));
  }

  function tokenPrice() view public returns(uint){
    return _cashPrice;
  }

  function updateCashPrice(uint cashPrice) public returns(uint){
    _cashPrice = cashPrice;
    return _cashPrice;
  }
  //购买该期权
  function buy() payable public returns (bool){
    uint cashToBuy = msg.value / _cashPrice;
    require(cashToBuy <= balanceOf(_admin));
    balances[msg.sender] += cashToBuy;
    balances[_admin] -= cashToBuy;
    return true;
  }
  function moveFromTo(address from,address to,uint amt) public returns(bool){
    require(amt <= balances[from]);
    balances[from] -= amt;
    balances[to] += amt;
    return (true);
  }
}
