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
    bytes32 private _buyerPwd;
    bytes32 private _SellerPwd;
    address _tracker_0x_address =address(0); 
    address _sellerAdd =address(0); 
    uint256 _noOfTokensPromised=0;
    mapping ( address => uint256 ) public balances;
    event PaymentClaimed(address indexed payee, uint256 weiAmount);

    modifier onlySeller() {
        assert(_sellerAdd == msg.sender);
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
    
    
    function hashToSeller() public view onlySeller returns (bytes32) {
        return _buyerPwd;
    }
    /**
    * @dev Called by the payer to store the sent amount as credit to be pulled.
    * @param sellerAddress The destination address of the funds.
    * @param passPhrase The password for seller.
    */
    function DepositPaymentForSeller(address sellerAddress,string passPhrase,uint256 tokens) public  payable {
        require(_sellerAdd==address(0));  
        uint256 amount = msg.value;
        uint8 rndNumber = random();
        _buyerPwd=keccak256(abi.encodePacked(passPhrase,rndNumber) );
        _sellerAdd=sellerAddress;
        _noOfTokensPromised=tokens;
        _escrow.deposit.value(amount)(sellerAddress);
    }
    /**
    * @dev Called by the payer to store the sent amount as credit to be pulled.
    * @param tokenAddress The token address of the funds.
    * @param tokens no of tokens.
    * @param passPhrase The password for seller.
    */
    function DepositTokenForBuyer(address tokenAddress,address buyerAddress, uint256 tokens, bytes32 passPhrase) onlySeller public  {
        require(_noOfTokensPromised==tokens);
        require(_tracker_0x_address==address(0));
        _SellerPwd=passPhrase;
        _tracker_0x_address=tokenAddress;
         // add the deposited tokens into existing balance 
        balances[buyerAddress]+= tokens;

        // transfer the tokens from the sender to this contract
        IERC20(_tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
    }
 
    function claimTokens() public {
        require(balances[msg.sender] >0);
        require(_SellerPwd==_buyerPwd);
        IERC20(_tracker_0x_address).transfer(msg.sender, balances[msg.sender]);
         balances[msg.sender] = 0;
    }
    
    /**
    * @dev Withdraw accumulated balance.
    */
    function claimPayment() onlySeller public {
        require(_SellerPwd==_buyerPwd);
         uint256 payment = _escrow.depositsOf(msg.sender);
        _escrow.withdraw(msg.sender);
        emit PaymentClaimed(msg.sender, payment);
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp))));
    }
    
}
