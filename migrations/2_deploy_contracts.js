var Voting = artifacts.require("./Voting.sol");
var SSEoption = artifacts.require("./SSEoption.sol");
var Cash = artifacts.require("./Cash.sol");

var Token1 = artifacts.require("./Token1.sol");
// var Token2 = artifacts.require("./Token2.sol");
// var Token3 = artifacts.require("./Token3.sol");
// var Token4 = artifacts.require("./Token4.sol");
// var Token5 = artifacts.require("./Token5.sol");
// var Token6 = artifacts.require("./Token6.sol");
// var Token7 = artifacts.require("./Token7.sol");
// var Token8 = artifacts.require("./Token8.sol");
// var Token9 = artifacts.require("./Token9.sol");
module.exports = function(deployer) {
  deployer.deploy(Voting, 1000, web3.toWei('0.1', 'ether'), ['Rama', 'Nick', 'Jose']);
  deployer.deploy(SSEoption);

  deployer.deploy(Cash,web3.toWei('0.1','ether'));
  deployer.deploy(Token1);
  // deployer.deploy(Token2);
  // deployer.deploy(Token3);
  // deployer.deploy(Token4);
  // deployer.deploy(Token5);
  // deployer.deploy(Token6);
  // deployer.deploy(Token7);
  // deployer.deploy(Token8);
  // deployer.deploy(Token9);
};
