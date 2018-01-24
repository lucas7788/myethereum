pragma solidity ^0.4.18;
contract SSEoption{
  //欧式期权合约
  struct EurOption{
    uint optionId;//具有唯一性
    uint status;//合约状态,0代表未成交
    address accountA;//账户地址,卖期权的账户
    address accountB;//买期权的账户
    address tokenAddress;
    string tokenName;//证券资产名称
    uint tokenNum;//数量
    uint price;//证券资产价格
    uint premium;//权利金
    uint date;//交割日期yyyyMMdd
  }

  //美式期权合约
  struct USAOption{
    uint optionId;//具有唯一性
    uint status;//合约状态,0代表未成交
    address accountA;//账户地址,卖期权的账户
    address accountB;//买期权的账户
    address tokenAddress;
    string tokenName;//证券资产名称
    uint tokenNum;//数量
    uint price;//证券资产价格
    uint premium;//权利金
    uint dateStart;//交割日期yyyyMMdd
    uint dateEnd;//交割结束日期
  }

  uint public _totalEurOption;//欧式期权合约数量
  uint public _totalUSAOption;//美式期权合约数量
  address _admin;
  uint _currDate;//当前日期,只有_admin才可以修改
  mapping(uint => EurOption) eurOptions;//
  mapping(uint => USAOption) usaOptions;//
  address _cashAddress;
  mapping(address => mapping(address => uint)) public tokens;//存取token账户,tokens[0]代表以太，tokens[1]代表冻结

  function SSEoption() public{
    _currDate = 0;
    _totalEurOption = 0;
    _totalUSAOption = 0;
    _admin = msg.sender;
  }

  function setCashAddress(address cash) public returns(bool){
    require(msg.sender == _admin);
    _cashAddress = cash;
    return (true);
  }

  //存币
  function depositToken(address token, uint amt) public returns(bool){
    require(token != 0 );
    require(Token(token).transferFrom(msg.sender,this,amt));
    tokens[token][msg.sender] += amt;
    return true;
  }
  //取币
  function withdrawToken(address token, uint amt) public {
    require(token != 0);
    require(amt < tokens[token][msg.sender]);
    tokens[token][msg.sender] -= amt;
    require(Token(token).transfer(msg.sender,amt));
  }

  //查看approve方法是否正确执行
  function lookAllowance(address token,address _owner, address _spender) public view returns (uint256) {
    return Token(token).allowance(_owner,_spender);
  }

  function getTokenBalances(address token) view public returns(uint){
    return tokens[token][msg.sender];
  }

  //获得当前日期
  function getCurrDate() constant public returns (uint){
    return _currDate;
  }

  //更新当前日期
  function updateCurrDate(uint date) public{
    require(msg.sender == _admin);//必须是管理员才可以修改
    _currDate = date;
  }
 //创建欧式期权
 function createEurOption(address tokenAddress,string tokenName,uint tokenNum,uint optionPrice,uint premium,uint date) public
   returns(bool){

   require(tokenNum <= tokens[tokenAddress][msg.sender]);
   uint optionId = _totalEurOption;
   eurOptions[optionId] = EurOption(optionId,0,msg.sender,0,tokenAddress,tokenName,tokenNum,optionPrice,premium,date);

   tokens[tokenAddress][msg.sender] -= tokenNum;//冻结相应的token
   tokens[tokenAddress][_admin] += tokenNum;//冻结的token又管理员保存
   _totalEurOption++;
   return (true);
 }

 //创建美式期权
 function createUSAOption(address tokenAddress,
 string tokenName,//证券资产名称
 uint tokenNum,//数量
 uint price,//证券资产价格
 uint premium,//权利金
 uint dateStart,//交割日期yyyyMMdd
 uint dateEnd//交割结束日期
 ) public returns(bool){
   require(tokenNum <= tokens[tokenAddress][msg.sender]);
   uint optionId = _totalUSAOption;
   usaOptions[optionId] = USAOption(optionId,0,msg.sender,0,tokenAddress,tokenName,tokenNum,price,premium,dateStart,dateEnd);

   tokens[tokenAddress][msg.sender] -= tokenNum;//冻结相应的token
   tokens[tokenAddress][_admin] += tokenNum;//冻结的token由管理员保存
   _totalUSAOption++;
   return (true);
 }


 function getEurOption(uint optionId) view public returns(address tokenAddress,string tokenName,uint status,//合约状态,0代表未成交
 address accountA,//账户地址,卖期权的账户
 address accountB,//买期权的账户
 uint tokenNum,uint optionPrice,uint premium,uint date){
   tokenAddress = eurOptions[optionId].tokenAddress;
   status = eurOptions[optionId].status;
   accountA = eurOptions[optionId].accountA;
   accountB = eurOptions[optionId].accountB;
   tokenName = eurOptions[optionId].tokenName;
   tokenNum = eurOptions[optionId].tokenNum;
   optionPrice = eurOptions[optionId].price;
   premium = eurOptions[optionId].premium;
   date = eurOptions[optionId].date;
 }

 //购买美式期权
 function buyUSAOption(uint optionId,uint cash) public returns (bool){

   require(usaOptions[optionId].premium <= cash);//
   require(usaOptions[optionId].status == 0);//0代表未成交
   require(cash < tokens[_cashAddress][msg.sender]);
   tokens[_cashAddress][msg.sender] -= cash;//付权利金
   tokens[_cashAddress][usaOptions[optionId].accountA] += cash;//账户A获得权力金

   usaOptions[optionId].accountB = msg.sender;//accountB代表付钱的账户,accountB是付钱账户,获得权力
   usaOptions[optionId].status = 1;//代表已成交未行权

   return (true);
 }

 //美式期权行权
 function executeRightUSA(uint optionId) public returns(bool){
   require(usaOptions[optionId].accountB == msg.sender);
   require(usaOptions[optionId].tokenNum < tokens[usaOptions[optionId].tokenAddress][_admin]);
   require(usaOptions[optionId].status == 1);
   require(usaOptions[optionId].dateStart <= _currDate);


   uint totalPrice = usaOptions[optionId].tokenNum * usaOptions[optionId].price;
   require(usaOptions[optionId].tokenNum * usaOptions[optionId].price <= tokens[_cashAddress][msg.sender]);
   tokens[_cashAddress][msg.sender] -= totalPrice;
   tokens[_cashAddress][usaOptions[optionId].accountA] += totalPrice;

   tokens[usaOptions[optionId].tokenAddress][msg.sender] += usaOptions[optionId].tokenNum;
   tokens[usaOptions[optionId].tokenAddress][_admin] -= usaOptions[optionId].tokenNum;

   usaOptions[optionId].status = 2;//代表已行权
 }

 //购买欧式期权
 function buyEurOption(uint optionId,uint cash) public returns (bool){

   require(eurOptions[optionId].premium <= cash);//
   require(eurOptions[optionId].status == 0);//0代表未成交
   require(cash <= tokens[_cashAddress][msg.sender]);
   tokens[_cashAddress][msg.sender] -= cash;//付权利金
   tokens[_cashAddress][eurOptions[optionId].accountA] += cash;//账户A获得权力金

   eurOptions[optionId].accountB = msg.sender;//accountB代表付钱的账户,accountB是付钱账户
   eurOptions[optionId].status = 1;//代表已成交未行权
   return (true);
 }

 //欧式期权行权
 function executeRight(uint optionId) public returns(bool){
   require(eurOptions[optionId].accountB == msg.sender);
   require(eurOptions[optionId].tokenNum < tokens[eurOptions[optionId].tokenAddress][_admin]);
   require(eurOptions[optionId].status == 1);
   require(eurOptions[optionId].date == _currDate);

   uint totalPrice = eurOptions[optionId].tokenNum * eurOptions[optionId].price;
   require(eurOptions[optionId].tokenNum * eurOptions[optionId].price <= tokens[_cashAddress][msg.sender]);
   tokens[_cashAddress][msg.sender] -= totalPrice;
   tokens[_cashAddress][eurOptions[optionId].accountA] += totalPrice;

   tokens[eurOptions[optionId].tokenAddress][msg.sender] += eurOptions[optionId].tokenNum;
   tokens[eurOptions[optionId].tokenAddress][_admin] -= eurOptions[optionId].tokenNum;

   eurOptions[optionId].status = 2;//代表已行权
 }
}
contract Token {

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
