pragma solidity ^0.4.24;

import "./Escrow.sol";
import "./IERC20.sol";
/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use _asyncTransfer instead of send or transfer.
 */
contract BuyToken {
    Escrow private _escrow;
    address _tracker_0x_address =address(0); 
    address _sellerAdd =address(0); 
    address _buyerAdd =address(0); 
    uint256 _noOfTokensPromised=0;
    mapping ( address => uint256 ) public balances;
    event PaymentClaimed(address indexed payee, uint256 weiAmount);
    event TokensClaimed(address indexed payee, uint256 noOfTokens);

    modifier onlySeller() {
        assert(_sellerAdd == msg.sender);
        _;
    }
    modifier onlyBuyer() {
        assert(_buyerAdd == msg.sender);
        _;
    }
    constructor () internal {
        _escrow = new Escrow();
    }

    /**
    * @dev Returns the credit owed to an address.
    * @param sellerAddress The sellerAddress's address.
    */
    function payments(address sellerAddress) public view returns (uint256) {
        return _escrow.depositsOf(sellerAddress);
    }
    function buyerTokens(address buyerAddress) public view returns (uint256) {
        return balances[buyerAddress];
    }
           
    /**
    * @dev Called by the payer to store the sent amount as credit to be pulled.
    * @param sellerAddress The destination address of the funds.
    * @param tokenAddress The token address of the funds.
    */
    function DepositPaymentForSeller(address sellerAddress,address tokenAddress,uint256 tokens) public  payable {
        require(_sellerAdd==address(0));  
        uint256 amount = msg.value;
        _sellerAdd=sellerAddress;
        _buyerAdd=msg.sender;
        _tracker_0x_address=tokenAddress;
        _noOfTokensPromised=tokens;
        _escrow.deposit.value(amount)(sellerAddress);
    }
    /**
    * @dev Called by the payer to store the sent amount as credit to be pulled.
    * @param tokens no of tokens.
    */
    function DepositTokenForBuyer(address buyerAddress, uint256 tokens) onlySeller public  {
        require(_noOfTokensPromised==tokens);
        require(_tracker_0x_address!=address(0));
        
         // add the deposited tokens into existing balance 
        balances[buyerAddress]+= tokens;

        // transfer the tokens from the sender to this contract
        IERC20(_tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
    }
 
    function claimTokens() onlyBuyer public {
        require(balances[msg.sender] >0);
        uint256 noOfTokens =balances[msg.sender] ;
        IERC20(_tracker_0x_address).transfer(msg.sender, noOfTokens);
        balances[msg.sender] = 0;
        emit TokensClaimed(msg.sender, noOfTokens);
    }
    
    /**
    * @dev Withdraw accumulated balance.
    */
    function claimPayment() onlySeller public {
         uint256 payment = _escrow.depositsOf(msg.sender);
        _escrow.withdraw(msg.sender);
        emit PaymentClaimed(msg.sender, payment);
    }
    
    
    
}
