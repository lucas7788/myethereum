// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

/*
 * When you compile and deploy your Voting contract,
 * truffle stores the abi and deployed address in a json
 * file in the build directory. We will use this information
 * to setup a Voting abstraction. We will use this abstraction
 * later to create an instance of the Voting contract.
 * Compare this against the index.js from our previous tutorial to see the difference
 * https://gist.github.com/maheshmurthy/f6e96d6b3fff4cd4fa7f892de8a1a1b4#file-index-js
 */

import voting_artifacts from '../../build/contracts/Voting.json'
import cash_artifacts from '../../build/contracts/Cash.json'
//import euroption_artifacts from '../../build/contracts/EurOption.json'
import sseoption_artifacts from '../../build/contracts/SSEoption.json'
import token1_artifacts from '../../build/contracts/Token1.json'

const ipfsAPI = require('ipfs-api');
const ipfs = ipfsAPI({host: 'localhost', port: '5001', protocol: 'http'});

var Voting = contract(voting_artifacts);
var Cash = contract(cash_artifacts);
//var EurOption = contract(euroption_artifacts);
var SSEoption = contract(sseoption_artifacts);
var token1 = contract(token1_artifacts);

let candidates = {}
let eurOptions = {}
let usaOptions = {}

let tokenPrice = null;

$( document ).ready(function() {
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source like Metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }

  Voting.setProvider(web3.currentProvider);
  Cash.setProvider(web3.currentProvider);
  // EurOption.setProvider(web3.currentProvider);
  SSEoption.setProvider(web3.currentProvider);
  token1.setProvider(web3.currentProvider);
  populateCandidates();
});

let saveDataOnIpfs = (reader) => {
  return new Promise(function(resolve, reject) {
    const buffer = Buffer.from(reader,'utf-8');
    ipfs.add(buffer).then((response) => {
      console.log(response)
      resolve(response[0].hash);
    }).catch((err) => {
      console.error(err)
      reject(err);
    });
  });
}
//保存数据到ipfs，并把返回的hash保存到区块链上
window.saveDataToIpfs = function(data){
  let dataS = $("#dataipfs").val();
  saveDataOnIpfs(dataS).then((hash) => {
                console.log(hash);
                //这里执行把数据保存到链上的操作
              });
}

window.voteForCandidate = function(candidate) {
  let candidateName = $("#candidate").val();
  let voteTokens = $("#vote-tokens").val();
  $("#msg").html("Vote has been submitted. The vote count will increment as soon as the vote is recorded on the blockchain. Please wait.")
  $("#candidate").val("");
  $("#vote-tokens").val("");

  /* Voting.deployed() returns an instance of the contract. Every call
   * in Truffle returns a promise which is why we have used then()
   * everywhere we have a transaction call
   */
  Voting.deployed().then(function(contractInstance) {
    contractInstance.voteForCandidate(candidateName, voteTokens, {gas: 140000, from: web3.eth.accounts[0]}).then(function() {
      let div_id = candidates[candidateName];
      return contractInstance.totalVotesFor.call(candidateName).then(function(v) {
        $("#" + div_id).html(v.toString());
        $("#msg").html("");
      });
    });
  });
}

/* The user enters the total no. of tokens to buy. We calculate the total cost and send it in
 * the request. We have to send the value in Wei. So, we use the toWei helper method to convert
 * from Ether to Wei.
 */

window.buyTokens = function() {
  // let tokensToBuy = $("#buy").val();
  // let price = tokensToBuy * tokenPrice;
  // $("#buy-msg").html("Purchase order has been submitted. Please wait.");
  // Voting.deployed().then(function(contractInstance) {
  //   contractInstance.buy({value: web3.toWei(price, 'ether'), from: web3.eth.accounts[0]}).then(function(v) {
  //     $("#buy-msg").html("");
  //     web3.eth.getBalance(contractInstance.address, function(error, result) {
  //       $("#contract-balance").html(web3.fromWei(result.toString()) + " Ether");
  //     });
  //   })
  // });
  let tokensToBuy = $("#buy").val();
  let price = tokensToBuy * tokenPrice;
  $("#buy-msg").html("Purchase order has been submitted. Please wait.");
  Cash.deployed().then(function(contractInstance) {
    console.log(contractInstance);
    contractInstance.buy({value: web3.toWei(price, 'ether'),from:web3.eth.accounts[3]}).then(function(v) {
      $("#buy-msg").html("");
      web3.eth.getBalance(contractInstance.address, function(error, result) {
        $("#contract-balance").html(web3.fromWei(result.toString()) + " Ether");
      });
    })
  });
  populateTokenData();
}

window.lookupVoterInfo = function() {
  let address = $("#voter-info").val();
  Voting.deployed().then(function(contractInstance) {
    contractInstance.voterDetails.call(address).then(function(v) {
      $("#tokens-bought").html("Total Tokens bought: " + v[0].toString());
      let votesPerCandidate = v[1];
      $("#votes-cast").empty();
      $("#votes-cast").append("Votes cast per candidate: <br>");
      let allCandidates = Object.keys(candidates);
      for(let i=0; i < allCandidates.length; i++) {
        $("#votes-cast").append(allCandidates[i] + ": " + votesPerCandidate[i] + "<br>");
      }
    });
  });
}

/* Instead of hardcoding the candidates hash, we now fetch the candidate list from
 * the blockchain and populate the array. Once we fetch the candidates, we setup the
 * table in the UI with all the candidates and the votes they have received.
 */
function populateCandidates() {
  // Voting.deployed().then(function(contractInstance) {
  //   contractInstance.allCandidates.call().then(function(candidateArray) {
  //     console.log(candidateArray);
  //     for(let i=0; i < candidateArray.length; i++) {
  //       /* We store the candidate names as bytes32 on the blockchain. We use the
  //        * handy toUtf8 method to convert from bytes32 to string
  //        */
  //       candidates[web3.toUtf8(candidateArray[i])] = "candidate-" + i;
  //
  //     }
  //     setupCandidateRows();
  //     populateCandidateVotes();
  //     populateTokenData();
  //   });
  // });

  SSEoption.deployed().then(function(contractInstance){
    contractInstance._totalEurOption().then(function(totalEurOption){
      console.log(totalEurOption);
      for(let i=0;i<totalEurOption;i++){
        contractInstance.getEurOption(i).then(
          function(eurOption){
            console.log(eurOption);
            $("#candidate-rows").append("<tr><td>" + i + "</td><td>" + eurOption[2] +"</td><td>" + eurOption[3] +"</td><td width = '" + 20+"px" + "'>" + eurOption[4] + "</td></tr>");
          }
        );
      }
      setupCandidateRows();
      populateCandidateVotes();
      populateTokenData();
    });
  });
}

function populateCandidateVotes() {
  let candidateNames = Object.keys(candidates);
  for (var i = 0; i < candidateNames.length; i++) {
    let name = candidateNames[i];
    Voting.deployed().then(function(contractInstance) {
      contractInstance.totalVotesFor.call(name).then(function(v) {
        $("#" + candidates[name]).html(v.toString());
      });
    });
  }
}

function setupCandidateRows() {
  // Object.keys(candidates).forEach(function (candidate) {
  //   $("#candidate-rows").append("<tr><td>" + candidate + "</td><td id='" + candidates[candidate] + "'></td></tr>");
  // });
  Object.keys(eurOptions).forEach(function (eurOption) {
    console.log();
    console.log(eurOption);
    $("#candidate-rows").append("<tr><td>" + eurOption + "</td><td id='" + eurOptions[eurOption] + "'></td></tr>");
  });
}

/* Fetch the total tokens, tokens available for sale and the price of
 * each token and display in the UI
 */
function populateTokenData() {
  // Voting.deployed().then(function(contractInstance) {
  //   contractInstance.totalTokens().then(function(v) {
  //     $("#tokens-total").html(v.toString());
  //   });
  //   contractInstance.tokensSold.call().then(function(v) {
  //     $("#tokens-sold").html(v.toString());
  //   });
  //   contractInstance.tokenPrice().then(function(v) {
  //     tokenPrice = parseFloat(web3.fromWei(v.toString()));
  //     $("#token-cost").html(tokenPrice + " Ether");
  //   });
  //   web3.eth.getBalance(contractInstance.address, function(error, result) {
  //     $("#contract-balance").html(web3.fromWei(result.toString()) + " Ether");
  //   });
  // });
  Cash.deployed().then(function(contractInstance) {
    contractInstance.totalSupply().then(function(v) {
      $("#tokens-total").html(v.toString());
    });
    contractInstance.tokensSold.call().then(function(v) {
      $("#tokens-sold").html(v.toString());
    });
    contractInstance._cashPrice().then(function(v) {
      tokenPrice = parseFloat(web3.fromWei(v.toString()));
      $("#token-cost").html(tokenPrice + " Ether");
    });
    web3.eth.getBalance(contractInstance.address, function(error, result) {
      $("#contract-balance").html(web3.fromWei(result.toString()) + " Ether");
    });
  });
}
