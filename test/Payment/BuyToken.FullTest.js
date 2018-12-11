const { ethGetBalance } = require('../helpers/web3');
const { ether } = require('../helpers/ether');
const shouldFail = require('../helpers/shouldFail');
var Web3 = require('web3');
// TODO: Fix state tests
// TODO: Consider gas and fix gas tests

const BigNumber = web3.BigNumber;
const weiToEth = 1000000000000000000;
require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const BuyTokenMock = artifacts.require('./BuyTokenMock.sol');
const HToken = artifacts.require('./Token.sol');

contract('Buy Token', function ([_, buyer, seller, otherEntity]) {
  const amount = ether(1.0);
  const gas = ether(0.1);
 
  beforeEach(async function () {
    this.token = await HToken.new();
    console.log('this.token.address ' + this.token.address)

    this.buyToken = await BuyTokenMock.new();
    console.log('this.buyToken.address ' + this.buyToken.address)

    const walletBalanceInit = await this.token.balanceOf.call(_)
    console.log(`wallet initial  token balance = ${walletBalanceInit}`)

    await this.token.transfer(seller,1000);
   
    await this.buyToken.DepositPaymentForSeller(seller,this.token.address,100, { from: buyer, value:amount });
    console.log(`Seller Ether waiting = ` +  await this.buyToken.payments(seller));
    
    console.log(`Seller Token = ` + await this.token.balanceOf.call(seller));
    console.log(`Buyer Token = ` + await this.token.balanceOf.call(buyer));

    await this.token.approve(this.buyToken.address, 100,{from:seller});
   
    await this.buyToken.DepositTokenForBuyer(buyer,100,{from:seller} );
    console.log(`Seller Token after transfer = ` + await this.token.balanceOf.call(seller));
    console.log(`Buyer Token waiting = ` + await this.buyToken.buyerTokens(buyer));

    await this.buyToken.claimTokens({from:buyer});
    console.log(`Buyer Token = ` + await this.token.balanceOf.call(buyer));

    console.log(`Seller Ether before claim = ` + await ethGetBalance(seller));
    await this.buyToken.claimPayment({from:seller});
    console.log(`Seller Ether = ` + await ethGetBalance(seller));
    

  });
  describe('Buy Process', function () {
    it('should run full cycle', async function () {
      // (await this.contract.currentState()).should.be.equal(stateUninitialized);
    });
  });
  
});
