const { ethGetBalance } = require('../helpers/web3');
const { ether } = require('../helpers/ether');
const shouldFail = require('../helpers/shouldFail');
const { balanceDifference } = require('../helpers/balanceDifference');
const expectEvent = require('../helpers/expectEvent');
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
   // console.log('this.token.address ' + this.token.address)

    this.buyToken = await BuyTokenMock.new();
    //console.log('this.buyToken.address ' + this.buyToken.address)

    const walletBalanceInit = await this.token.balanceOf.call(_)
    //console.log(`wallet initial  token balance = ${walletBalanceInit}`)

    await this.token.transfer(seller,1000);
   
  });
  describe('Buy Token', function () {
    it('Should not be able to change seller', async function () {
      await this.buyToken.DepositPaymentForSeller(seller,this.token.address,100, { from: buyer, value:amount });
      await shouldFail.reverting(this.buyToken.DepositPaymentForSeller(seller,this.token.address,100, { from: buyer, value:amount }));
    });
    it('Seller Should not deposit different no of tokens', async function () {
      await this.buyToken.DepositPaymentForSeller(seller,this.token.address,100, { from: buyer, value:amount });
      await this.token.approve(this.buyToken.address, 100,{from:seller});
      await shouldFail.reverting(this.buyToken.DepositTokenForBuyer(buyer,10,{from:seller} ));
    });
    it('Buyer Should be able to claim tokens', async function () {
      await this.buyToken.DepositPaymentForSeller(seller,this.token.address,100, { from: buyer, value:amount });
      await this.token.approve(this.buyToken.address, 100,{from:seller});
      await this.buyToken.DepositTokenForBuyer(buyer,100,{from:seller} );
      await this.buyToken.claimTokens({from:buyer});
      (await this.token.balanceOf.call(buyer)).should.be.bignumber.equal(100);
    });
    it('Seller Should be able to claim payment', async function () {
      await this.buyToken.DepositPaymentForSeller(seller,this.token.address,100, { from: buyer, value:amount });
      await this.token.approve(this.buyToken.address, 100,{from:seller});
      await this.buyToken.DepositTokenForBuyer(buyer,100,{from:seller} );
      const { logs } = await this.buyToken.claimPayment({from:seller});
      expectEvent.inLogs(logs, 'PaymentClaimed', {
        payee: seller,
        weiAmount: amount,
      });
      
       
     
    });

    
  });
  
});
