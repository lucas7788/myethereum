pragma solidity ^0.4.18;
import "./Dbcc.sol";
contract CallOption {//认购期权合约
  mapping(address => mapping(address => uint)) tokens;
  uint currBlockNum;
  address _cashAddress;
  address _dbccAddr;
  function updateTokenAddr(address cashAddr,address dbccAddr) returns(bool){
    _cashAddress = cashAddr;
    _dbccAddr = dbccAddr;
    return true;
  }
  //甲方将token转移到期权合约
  function calloption(address tokenAddr,address accountA,address accountB) public returns(bool) {
    Dbcc(_dbccAddr).transferFromTo(tokenAddr,accountA,this,10000);//甲方将token转移到合约
    tokens[tokenAddr][accountA] += 10000;
    tokens[tokenAddr][this] += 10000;

    Dbcc(_dbccAddr).transferFromTo(_cashAddress,accountB,this,20000);//乙方将cash转移到合约
    tokens[_cashAddress][accountB] += 20000;//账户持有量
    tokens[_cashAddress][this] += 20000;//合约持有量
    currBlockNum = block.number;//当前的区块高度
    return true;
   }
  //当满足某一条件时，甲方可以提cash
   function receiveToken(address accountA) public returns(bool){
     require(100 < block.number-currBlockNum);//
     require(20000 < tokens[_cashAddress][this]);
     tokens[_cashAddress][accountA] += 20000;
     tokens[_cashAddress][this] -= 20000;
   }
   //乙方用cash换token
   function changeToken(address tokenAddr,address accountB,uint amt) public returns(bool){
     require(block.number-currBlockNum <= 1000);
     require(Dbcc(_dbccAddr).transferFromTo(_cashAddress,accountB,this,amt));//乙方付钱
     require(Dbcc(_dbccAddr).transferFromTo(tokenAddr,this,accountB,amt/50));//合约将token转给乙方
     /* require();//甲方获得cash */
   }

   //1000个区块以后，甲方可以提取合约中剩余的token——A
   function withdrawToken(address tokenAddr,address accountA) public returns(bool){
     require(0 < tokens[tokenAddr][this]);
     Dbcc(_dbccAddr).transferFromTo(tokenAddr,this,accountA,tokens[tokenAddr][this]);
   }
}
