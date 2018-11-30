require('babel-register');
require('babel-polyfill');

var provider;
var HDWalletProvider = require('truffle-hdwallet-provider');
var mnemonic = 'beauty notable increase opera double hire witness solar casino dash habit filter';
var infura_apikey = "P6LEmOqq2Q6EvqtzK2YS";

if (!process.env.SOLIDITY_COVERAGE){
  provider = new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/')
}


module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      gas: 0xfffffffffff,
      gasPrice: 0x01
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"+infura_apikey),
      network_id: 3,
      gas: 4700000,
      gasPrice: 25000000000
    },
    kovan: {
      provider: new HDWalletProvider(mnemonic, "https://kovan.infura.io/"+infura_apikey),
      network_id: 3,
      gas: 4700000,
      gasPrice: 25000000000
    },
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8555,
      gas: 0xfffffffffff,
      gasPrice: 0x01
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
