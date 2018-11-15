pragma solidity ^0.4.24;

/**
 * @title SimpleBet
 * @dev This contract is meant to hold a bet between two parties and pay out the
 * winner after the conclusion of the bet. This contract is meant to be used
 * with two parties who want to make a 1:1 bet, as both parties must send an
 * equal number of ETH. The initiator can withdraw his bet prior to the
 * counterparty sending his contribution. After both contributions have been
 * made, the original contributions cannot be withdrawan until the conclusion
 * of the bet.
 *
 * @dev The flow of contract is as follows:
 * 1) anyone uploads the contract
 * 2) the initiator calls initiateBet() and sends the amount of ETH they want to bet in the transaction
 * 3) the counterparty calls startBet() and sends the same amount of ETH the initiator sent
 * 4) either the initiator or the counterparty can close the bet and determine the winner
 */
contract SimpleBet {

  /* Variables */
  address public initiator;
  address public counterparty;
  uint256 public betAmount;

  enum BetState { Uninitialized, Initialized, Started, Ended }
  BetState private _currentState;

  /* Events */
  event BetInitiated(address indexed initiator, address indexed counterparty, uint256 indexed betAmount);
  event BetStart(address indexed initiator, address indexed counterparty, uint256 indexed betAmount);
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
  function initiateBet(address _counterparty)
    public
    payable
  {
    require(_currentState == BetState.Uninitialized, "The bet must not have yet been initiated");
    betAmount = msg.value;
    require(betAmount > 0, "There must be a betAmount");

    initiator = msg.sender;
    counterparty = _counterparty;
    _currentState = BetState.Initialized;

    emit BetStart(initiator, counterparty, betAmount);
  }

  /// @dev Start the bet by providing the second contribution.
  /// @notice This is only callable by the counterparty specified in initiateBet()
  function startBet()
    public
    payable
  {
    require(_currentState == BetState.Initialized, "The bet must have been initialized");
    require(msg.sender == counterparty, "Contender must be the expected person");
    require(msg.value == betAmount, "The contender must match the bet");

    _currentState = BetState.Started;
    emit BetStart(initiator, counterparty, betAmount);
  }

  /// @dev Finalize the bet and payout the winner
  /// @param isInitiatorWinner Result of the bet to determin who gets paid.
  function closeBet(bool isInitiatorWinner)
    public
    payable
  {
    require(_currentState == BetState.Started, "Bet must have been started");
    require(msg.sender == initiator || msg.sender == counterparty);

    _currentState = BetState.Ended;

    if (isInitiatorWinner) {
      initiator.transfer(address(this).balance);
      emit BetEnd(initiator);
    } else {
      counterparty.transfer(address(this).balance);
      emit BetEnd(counterparty);
    }
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
}
