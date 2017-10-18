pragma solidity ^0.4.13;

import './HydroCoin.sol';
import './HydroCoinPresale.sol';

import './installed_contracts/zeppelin/contracts/ownership/Ownable.sol';
import './installed_contracts/zeppelin/contracts/math/SafeMath.sol';
import "./installed_contracts/zeppelin/contracts/lifecycle/Pausable.sol";

contract HydroCoinCrowdsale is Ownable, Pausable {
  using SafeMath for uint256;

  // The token being sold
  HydroCoin public token;

  // start and end times
  uint256 public startTimestamp;
  uint256 public endTimestamp;

  // address where funds are collected
  address public hardwareWallet;


  mapping (address => uint256) public deposits;
  uint256 public numberOfPurchasers;

  // how many token units a buyer gets per wei
  uint[] rates = [120,115,110,105];
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;
  uint256 public tokensSold;

  uint256 public minContribution = 1 finney;

  uint256 public hardcap = 25000000 * 10 ** 18; // H2O
  uint256 public coinsToSell;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event MainSaleClosed();

  uint256 public weiRaisedInPresale  = 0 ether;
  uint256 public tokensSoldInPresale = 0 * 10 ** 18;

// REGISTRY FUNCTIONS 

  mapping (address => bool) public registered;
  address public registrar;
  function setReg(address _newReg) onlyOwner {
    registrar = _newReg;
  }

  function register(address participant) {
    require(msg.sender == registrar);
    registered[participant] = true;
  }

// END OF REGISTRY FUNCTIONS

  function setCoin(HydroCoin _coin) onlyOwner {
    token = _coin;
  }

  function setWallet(address _wallet) onlyOwner {
    hardwareWallet = _wallet;
  }

  function setTokensSoldInPresale(uint256 presale) onlyOwner {
    tokensSoldInPresale = presale;
    coinsToSell = hardcap.sub(tokensSoldInPresale);
  }

  function HydroCoinCrowdsale() {
    startTimestamp = 1508320800;
    endTimestamp = startTimestamp + 4 weeks;
    rate = 120;
    hardwareWallet = 0xa92F40333Ba51f169FC2791c5534E01a87dF21e3;
    token = HydroCoin(0xFeeD1a53bd53FFE453D265FC6E70dD85f8e993b6);
    tokensSoldInPresale = 1187481740794000000000000; // 187500
    coinsToSell = hardcap.sub(tokensSoldInPresale);


//////   //    /////     BIG BLOODY REMINDER   The code below is for testing purposes
//   //  //   //   //    BIG BLOODY REMINDER   If you are not the developer of this code
/////    //   //         BIG BLOODY REMINDER   And you can see this, SHOUT coz it should 
//  ///  //   //  ///    BIG BLOODY REMINDER   Not be here in production and all hell will
//  ///  //   //   //    BIG BLOODY REMINDER   Break loose, the gates of hell will open and
//////   //    //////    BIG BLOODY REMINDER   Winged monstors and daemons will roam free  
//
//    // startTimestamp = 1504605600;
//    // endTimestamp = startTimestamp + 4 weeks;
//
//////   //    /////     BIG BLOODY REMINDER   The code above is for testing purposes
//   //  //   //   //    BIG BLOODY REMINDER   If you are not the developer of this code
/////    //   //         BIG BLOODY REMINDER   And you can see this, SHOUT coz it should 
//  ///  //   //  ///    BIG BLOODY REMINDER   Not be here in production and all hell will
//  ///  //   //   //    BIG BLOODY REMINDER   Break loose, the gates of hell will open and
//////   //    //////    BIG BLOODY REMINDER   Winged monstors and daemons will roam free  




    minContribution = 1 finney;

    require(startTimestamp >= now);
    require(endTimestamp >= startTimestamp);
  }

  // check if valid purchase
  modifier validPurchase {
    // REGISTRY REQUIREMENT
    require(registered[msg.sender]);
    // END OF REGISTRY REQUIREMENT
    require(now >= startTimestamp);
    require(now < endTimestamp);
    require(msg.value >= minContribution);
    rate = rates[(now - startTimestamp) / (1 weeks)];
    uint256 thisGuysTokens = rate.mul(msg.value);
    require(tokensSold.add(thisGuysTokens) <= coinsToSell);
    _;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    if (now > endTimestamp) 
        return true;
    if (tokensSold >= coinsToSell - minContribution.mul(120))
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
    
    rate = rates[(now - startTimestamp) / (1 weeks)];
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokens);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    hardwareWallet.transfer(msg.value);
  }

  // finish mining coins and transfer ownership of Change coin to owner
  function finishMinting() public onlyOwner {
    require(hasEnded());
    uint issuedTokenSupply = token.totalSupply();
    uint restrictedTokens = 100000000 * 10 ** 18; // 100 M H20
    restrictedTokens = restrictedTokens.sub(issuedTokenSupply);
    token.mint(hardwareWallet, restrictedTokens);
    token.finishMinting();
    token.transferOwnership(owner);
    MainSaleClosed();
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

    function emergencyERC20Drain( ERC20 theToken, uint amount ) {
        theToken.transfer(owner, amount);
    }


}
