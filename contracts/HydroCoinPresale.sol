pragma solidity ^0.4.13;

import './HydroCoin.sol'; 
import './installed_contracts/zeppelin/contracts/ownership/Ownable.sol';
import './installed_contracts/zeppelin/contracts/math/SafeMath.sol';
import "./installed_contracts/zeppelin/contracts/lifecycle/Pausable.sol";

contract HydroCoinPresale is Ownable,Pausable {
  using SafeMath for uint256;

  // The token being sold
  HydroCoin public token;

  // start and end block where investments are allowed (both inclusive)
  uint256 public startTimestamp; 
  uint256 public endTimestamp;

  // address where funds are collected
  address public hardwareWallet;

  mapping (address => uint256) public deposits;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  // minimum contributio to participate in tokensale
  uint256 public minContribution;

  // maximum amount of ether being raised
  uint256 public hardcap;

  // amount to allocate to vendors
  uint256 public vendorAllocation;

  // number of participants in presale
  uint256 public numberOfPurchasers = 0;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event PreSaleClosed();

  function setWallet(address _wallet) onlyOwner {
    hardwareWallet = _wallet;
  }

  function HydroCoinPresale() {
    startTimestamp = 1506333600;
    endTimestamp = startTimestamp + 1 weeks;

//////   //    /////     BIG BLOODY REMINDER   The code below is for testing purposes
//   //  //   //   //    BIG BLOODY REMINDER   If you are not the developer of this code
/////    //   //         BIG BLOODY REMINDER   And you can see this, SHOUT coz it should 
//  ///  //   //  ///    BIG BLOODY REMINDER   Not be here in production and all hell will
//  ///  //   //   //    BIG BLOODY REMINDER   Break loose, the gates of hell will open and
//////   //    //////    BIG BLOODY REMINDER   Winged monstors and daemons will roam free  

    startTimestamp = 1503506996;
    endTimestamp = startTimestamp + 1 weeks;

//////   //    /////     BIG BLOODY REMINDER   The code above is for testing purposes
//   //  //   //   //    BIG BLOODY REMINDER   If you are not the developer of this code
/////    //   //         BIG BLOODY REMINDER   And you can see this, SHOUT coz it should 
//  ///  //   //  ///    BIG BLOODY REMINDER   Not be here in production and all hell will
//  ///  //   //   //    BIG BLOODY REMINDER   Break loose, the gates of hell will open and
//////   //    //////    BIG BLOODY REMINDER   Winged monstors and daemons will roam free  



    rate = 125;
    hardwareWallet = 0X0;
    token = new HydroCoin();
    minContribution = 50 ether;
    hardcap = 1500 ether; 
    vendorAllocation = 1000000 * 10 ** 18; // H20

    require(startTimestamp >= now);
    require(endTimestamp >= startTimestamp);

    token.mint(hardwareWallet, vendorAllocation);
  }

  // check if valid purchase
  modifier validPurchase {
    require(now >= startTimestamp);
    require(now <= endTimestamp);
    require(msg.value >= minContribution);
    require(weiRaised.add(msg.value) <= hardcap);
    _;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    if (now > endTimestamp)
        return true;
    if (weiRaised >= hardcap)
        return true;
    return false;
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable validPurchase {
    require(beneficiary != 0x0);

    uint256 weiAmount = msg.value;

    if (deposits[msg.sender] == 0) {
        numberOfPurchasers++;
    }
    deposits[msg.sender] = weiAmount.add(deposits[msg.sender]);
    

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    hardwareWallet.transfer(msg.value);
  }

  // transfer ownership of the token to the owner of the presale contract
  function finishPresale() public onlyOwner {
    require(hasEnded());
    token.transferOwnership(owner);
    PreSaleClosed();
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

    function emergencyERC20Drain( ERC20 theToken, uint amount ) {
        theToken.transfer(owner, amount);
    }


}
