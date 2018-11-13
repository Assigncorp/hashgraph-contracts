pragma solidity ^0.4.24;

import "../libraries/math/SafeMath.sol";

/**
 * @title Oddsbet
 * @dev This contract is meant to hold a bet between two parties and pay out the
 * winner after the conclusion of the bet. This contract is meant to be used
 * with two parties who want to make a bet with odds, as both parties must send
 * their required number of ETH. The initiator can withdraw his bet prior to the
 * counterparty sending his contribution. After both contributions have been
 * made, the original contributions cannot be withdrawan until the conclusion
 * of the bet.
 */
contract OddsBet {
  using SafeMath for uint256;

  /* Variables */
  address public initiator;
  address public counterParty;
  uint256 public betAmount;
  uint256 public counterpartyBetAmount;

  enum BetState { Uninitialized, Initialized, Started, Ended }
  BetState public currentState;

  /* Events */
  event BetInitiated(address indexed initiator, address indexed counterParty, uint256 indexed betAmount, uint256 counterpartyBetAmount);
  event BetStart(address indexed initiator, address indexed counterParty, uint256 indexed betAmount, uint256 counterpartyBetAmount);
  event BetEnd(address indexed winner);
  event BetEndedEarly(address indexed initiator, uint256 indexed refund);

  constructor() public {
    currentState = BetState.Uninitialized;
  }

  /// @dev Iniate the bet and define the playsers and the bet betAmount
  /// @param _counterParty The counterparty to the bet
  /// @param odds Odds of the bet
  /// @param isFavored is the initiator favored. If so, divide for counterParty
  /// amount. If not, multiply for counterparty amount.
  function initiateBet(address _counterParty, uint256 odds, bool isFavored)
    public
    payable
  {
    require(currentState == BetState.Uninitialized, "The bet must not have yet been initiated");
    betAmount = msg.value;
    require(betAmount > 0, "There must be a betAmount");
    require(odds > 0, "There must be odds");

    if (isFavored) {
      counterpartyBetAmount = msg.value.mul(odds);
    } else {
      require(msg.value.mod(odds) == 0, "Amount contributed must be divisible by the odds");
      counterpartyBetAmount = msg.value.div(odds);
    }

    initiator = msg.sender;
    counterParty = _counterParty;
    currentState = BetState.Initialized;

    emit BetStart(initiator, counterParty, betAmount, counterpartyBetAmount);
  }

  /// @dev Start the bet by providing the second contribution.
  /// @notice This is only callable by the counterparty specified in initiateBet()
  function startBet()
    public
    payable
  {
    require(currentState == BetState.Initialized, "The bet must have been initialized");
    require(msg.sender == counterParty, "Contender must be the expected person");
    require(msg.value == counterpartyBetAmount, "The contender must match the bet");

    currentState = BetState.Started;
    emit BetStart(initiator, counterParty, betAmount, counterpartyBetAmount);
  }

  /// @dev Withdraw the initial contribution prior to the start of the bet
  /// @notice This can only be called by the initator
  function withdrawBet()
    public
  {
    require(currentState == BetState.Initialized, "The bet must have been initialized");
    require(msg.sender == initiator, "Contender must be the expected person");

    currentState = BetState.Ended;

    initiator.transfer(address(this).balance);

    emit BetEndedEarly(initiator, betAmount);
  }

  /// @dev Finalize the bet and payout the winner
  /// @param isInitiatorWinner Result of the bet to determin who gets paid.
  function closeBet(bool isInitiatorWinner)
    public
    payable
  {
    require(currentState == BetState.Started, "Bet must have been started");

    currentState = BetState.Ended;

    if (isInitiatorWinner) {
      initiator.transfer(address(this).balance);
      emit BetEnd(initiator);
    } else {
      counterParty.transfer(address(this).balance);
      emit BetEnd(counterParty);
    }
  }
}
