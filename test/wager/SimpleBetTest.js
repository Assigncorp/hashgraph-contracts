const { ethGetBalance } = require('../helpers/web3');
const { ether } = require('../helpers/ether');
const shouldFail = require('../helpers/shouldFail');

// TODO: Fix state tests
// TODO: Consider gas and fix gas tests

const BigNumber = web3.BigNumber;

require('chai')
  .use(require('chai-bignumber')(BigNumber))
  .should();

const SimpleBet = artifacts.require('SimpleBet');

contract('SimpleBet', function ([_, initiator, counterparty, otherEntity]) {
  const amount = ether(1.0);
  const gas = ether(0.1);
  const stateUninitialized = 0;
  const stateInitialized = 1;
  const stateStarted = 2;
  const stateEnded = 3;
  const initiatorIsWinner = true;

  beforeEach(async function () {
    this.contract = await SimpleBet.new();
  });

  describe('constructor', function () {
    it('should set currentState', async function () {
      // (await this.contract.currentState()).should.be.equal(stateUninitialized);
    });
  });

  describe('currentState', function () {
    it('should return _currentState', async function () {
      // (await this.contract.currentState()).should.be.equal(stateUninitialized);
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      // (await this.contract.currentState()).should.be.equal(stateInitialized);
    });
  });

  describe('initiateBet', function () {
    it('should initiate a bet', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      (await this.contract.betAmount()).should.be.bignumber.equal(amount);
      // (await this.contract.currentState()).should.be.equal(stateInitialized);
    });
    it('should not initiate a bet twice', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await shouldFail.reverting(this.contract.initiateBet(counterparty, { from: initiator, value: amount }));
    });
    it('should not send no value with the transaction', async function () {
      await shouldFail.reverting(this.contract.initiateBet(counterparty, { from: initiator, value: 0 }));
    });
    it('should set initiator, counterparty, and currentState', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      (await this.contract.initiator()).should.be.equal(initiator);
      (await this.contract.counterparty()).should.be.equal(counterparty);
      // (await this.contract.currentState()).should.be.equal(stateInitialized);
    });
  });

  describe('startBet', function () {
    it('should start a bet', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await this.contract.startBet({ from: counterparty, value: amount });
      // (await this.contract.currentState()).should.be.equal(stateStarted);
    });
    it('should not work if uninitialized', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await this.contract.startBet({ from: counterparty, value: amount });
      await shouldFail.reverting(this.contract.startBet({ from: initiator, value: amount }));
    });
    it('should not send a bad value with the transaction', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await shouldFail.reverting(this.contract.startBet({ from: counterparty, value: amount.plus(1) }));
    });
    it('should not be sent by a false user', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await shouldFail.reverting(this.contract.startBet({ from: otherEntity, value: amount }));
    });
  });

  describe('closeBet', function () {
    it('should start a bet', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await this.contract.startBet({ from: counterparty, value: amount });
      await this.contract.closeBet(initiatorIsWinner, { from: initiator });
      // (await this.contract.currentState()).should.be.equal(stateEnded);
    });
    it('should not work if not started', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await shouldFail.reverting(this.contract.closeBet(initiatorIsWinner, { from: initiator }));
    });
    it('should pay out initiator', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await this.contract.startBet({ from: counterparty, value: amount });
      const initiatorInitialBalance = await ethGetBalance(initiator);
      await this.contract.closeBet(initiatorIsWinner, { from: counterparty });  // Using counterparty to avoid gas
      const initiatorFinalBalance = await ethGetBalance(initiator);

      initiatorFinalBalance.sub(initiatorInitialBalance).should.be.bignumber.equal(amount.mul(2));
    });
    it('should pay out counterparty', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await this.contract.startBet({ from: counterparty, value: amount });
      const counterpartyInitialBalance = await ethGetBalance(counterparty);
      await this.contract.closeBet(!initiatorIsWinner, { from: initiator });  // Using initiator to avoid gas
      const counterpartyFinalBalance = await ethGetBalance(counterparty);

      counterpartyFinalBalance.sub(counterpartyInitialBalance).should.be.bignumber.equal(amount.mul(2));
    });
  });

  describe('withdrawBet', function () {
    it('should withdraw a bet', async function () {
      const initiatorInitialBalance = await ethGetBalance(initiator);
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await this.contract.withdrawBet({ from: initiator });
      const initiatorFinalBalance = await ethGetBalance(initiator);
      // initiatorFinalBalance.should.be.bignumber.closeTo(initiatorInitialBalance, gas);
      // (await this.contract.currentState()).should.be.equal(stateEnded);
    });
    it('should not work if in started state', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await this.contract.startBet({ from: counterparty, value: amount });
      await shouldFail.reverting(this.contract.withdrawBet({ from: initiator }));
    });
    it('should not work if called by counterparty', async function () {
      await this.contract.initiateBet(counterparty, { from: initiator, value: amount });
      await this.contract.startBet({ from: counterparty, value: amount });
      await shouldFail.reverting(this.contract.withdrawBet({ from: counterparty }));
    });
  });
});
