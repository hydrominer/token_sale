pragma solidity ^0.4.13;

import './installed_contracts/zeppelin/contracts/token/MintableToken.sol';
import "./installed_contracts/zeppelin/contracts/lifecycle/Pausable.sol";

contract HydroCoin is MintableToken, Pausable {
  string public name = "H2O Token";
  string public symbol = "H2O";
  uint256 public decimals = 18;

  //----- splitter functions


    event Ev(string message, address whom, uint256 val);

    struct XRec {
        bool inList;
        address next;
        address prev;
        uint256 val;
    }

    struct QueueRecord {
        address whom;
        uint256 val;
    }

    address public first = 0x0;
    address public last = 0x0;
    bool    public queueMode;
    uint256 public pos;

    mapping (address => XRec) public theList;

    QueueRecord[]  theQueue;

    function startQueueing() onlyOwner {
        queueMode = true;
        pos = 0;
    }

    function stopQueueing(uint256 num) onlyOwner {
        queueMode = false;
        for (uint256 i = 0; i < num; i++) {
            if (pos >= theQueue.length) {
                delete theQueue;
                return;
            }
            update(theQueue[pos].whom,theQueue[pos].val);
            pos++;
        }
        queueMode = true;
    } 

   function queueLength() constant returns (uint256) {
        return theQueue.length;
    }

    function addRecToQueue(address whom, uint256 val) internal {
        theQueue.push(QueueRecord(whom,val));
    }

    // add a record to the END of the list
    function add(address whom, uint256 value) internal {
        theList[whom] = XRec(true,0x0,last,value);
        if (last != 0x0) {
            theList[last].next = whom;
        } else {
            first = whom;
        }
        last = whom;
        Ev("add",whom,value);
    }

    function remove(address whom) internal {
        if (first == whom) {
            first = theList[whom].next;
            theList[whom] = XRec(false,0x0,0x0,0);
            Ev("remove",whom,0);
            return;
        }
        address next = theList[whom].next;
        address prev = theList[whom].prev;
        if (prev != 0x0) {
            theList[prev].next = next;
        }
        if (next != 0x0) {
            theList[next].prev = prev;
        }
        if (last == whom) {
            last = prev;
        }

        theList[whom] = XRec(false,0x0,0x0,0);
        Ev("remove",whom,0);
    }

    function update(address whom, uint256 value) internal {
        if (queueMode) {
            addRecToQueue(whom,value);
            return;
        }
        if (value != 0) {
            if (!theList[whom].inList) {
                add(whom,value);
            } else {
                theList[whom].val = value;
                Ev("update",whom,value);
            }
            return;
        }
        if (theList[whom].inList) {
                remove(whom);
        }
    }




// ----- H20 stuff -----


  /**
   * @dev Allows anyone to transfer the H20 tokens once trading has started
   * @param _to the recipient address of the tokens.
   * @param _value number of tokens to be transfered.
   */
  function transfer(address _to, uint _value) whenNotPaused returns (bool) {
      bool result = super.transfer(_to, _value);
      update(msg.sender,balances[msg.sender]);
      update(_to,balances[_to]);
      return result;
  }

  /**
   * @dev Allows anyone to transfer the H20 tokens once trading has started
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
      bool result = super.transferFrom(_from, _to, _value);
      update(_from,balances[_from]);
      update(_to,balances[_to]);
      return result;
  }

 /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
 
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
      bool result = super.mint(_to,_amount);
      update(_to,balances[_to]);
      return result;
  }

  function emergencyERC20Drain( ERC20 token, uint amount ) {
      token.transfer(owner, amount);
  }

 
}
