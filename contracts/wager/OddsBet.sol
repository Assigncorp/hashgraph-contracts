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
  address public counterparty;
  uint256 public betAmount;
  uint256 public counterpartyBetAmount;

  enum BetState { Uninitialized, Initialized, Started, Ended }
  BetState private _currentState;

  /* Events */
  event BetInitiated(address indexed initiator, address indexed counterparty, uint256 indexed betAmount, uint256 counterpartyBetAmount);
  event BetStart(address indexed initiator, address indexed counterparty, uint256 indexed betAmount, uint256 counterpartyBetAmount);
  event BetEnd(address indexed winner);
  event BetEndedEarly(address indexed initiator, uint256 indexed refund);

  constructor() public {
    _currentState = BetState.Uninitialized;
  }

  /// @dev Return the _currentState
  /// @notice This is required for testing since enums are not supported by the ABI
  /// https://ethereum.stackexchange.com/questions/29344/truffle-testing-enum-values?rq=1
  function currentState() public view returns (BetState) {
    return _currentState;
  }

  /// @dev Iniate the bet and define the playsers and the bet betAmount
  /// @param _counterparty The counterparty to the bet
  /// @param odds Odds of the bet
  /// @param isFavored is the initiator favored. If so, divide for counterparty
  /// amount. If not, multiply for counterparty amount.
  function initiateBet(address _counterparty, uint256 odds, bool isFavored)
    public
    payable
  {
    require(_currentState == BetState.Uninitialized, "The bet must not have yet been initiated");
    betAmount = msg.value;
    require(betAmount > 0, "There must be a betAmount");
    require(odds > 0, "There must be odds");

    if (isFavored) {
      counterpartyBetAmount = msg.value.mul(odds);
    } else {
      require(msg.value.mod(odds) == 0, "Amount contributed must be divisible by the odds");
      require(msg.value > odds, "Odds cannot surpass the amount");
      counterpartyBetAmount = msg.value.div(odds);
    }

    initiator = msg.sender;
    counterparty = _counterparty;
    _currentState = BetState.Initialized;

    emit BetStart(initiator, counterparty, betAmount, counterpartyBetAmount);
  }

  /// @dev Start the bet by providing the second contribution.
  /// @notice This is only callable by the counterparty specified in initiateBet()
  function startBet()
    public
    payable
  {
    require(_currentState == BetState.Initialized, "The bet must have been initialized");
    require(msg.sender == counterparty, "Contender must be the expected person");
    require(msg.value == counterpartyBetAmount, "The contender must match the bet");

    _currentState = BetState.Started;
    emit BetStart(initiator, counterparty, betAmount, counterpartyBetAmount);
  }

  /// @dev Withdraw the initial contribution prior to the start of the bet
  /// @notice This can only be called by the initator
  function withdrawBet()
    public
  {
    require(_currentState == BetState.Initialized, "The bet must have been initialized");
    require(msg.sender == initiator, "Contender must be the expected person");

    _currentState = BetState.Ended;

    initiator.transfer(address(this).balance);

    emit BetEndedEarly(initiator, betAmount);
  }

  /// @dev Finalize the bet and payout the winner
  /// @param isInitiatorWinner Result of the bet to determin who gets paid.
  function closeBet(bool isInitiatorWinner)
    public
    payable
  {
    require(_currentState == BetState.Started, "Bet must have been started");

    _currentState = BetState.Ended;

    if (isInitiatorWinner) {
      initiator.transfer(address(this).balance);
      emit BetEnd(initiator);
    } else {
      counterparty.transfer(address(this).balance);
      emit BetEnd(counterparty);
    }
  }
}
