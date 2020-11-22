// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Staking.sol";

contract StakedCFX is ERC20 {
    mapping (address => uint256) private _lastBlockCalc;
    // TODO: implement a lookup table for interest rates to save gas?

    Staking s = Staking(0x0888000000000000000000000000000000000002);

    constructor() public ERC20("Staked CFX", "sCFX") {}


    function _transfer(address sender, address recipient, uint256 amount) internal override {
        // get balances of sender + recipient
        uint256 balanceSender = balanceOf(sender);
        uint256 balanceRecipient = balanceOf(recipient);

        // calculate interest for sender + recipient
        uint interestSender = _calculateInterest(balanceSender, _lastBlockCalc[sender]);
        uint interestRecipient = 0; //interest = 0 (special case when recipient has never had tokens or currently has none)
        if (_lastBlockCalc[sender] != 0 || balanceRecipient != 0) {
            interestRecipient= _calculateInterest(balanceRecipient, _lastBlockCalc[sender]); //otherwise calculate
        }

        // update last block that calculation was run + interested was distributed
        _lastBlockCalc[sender] = block.number;
        _lastBlockCalc[recipient] = block.number;

        // mint interest tokens
        _mint(sender, interestSender);
        if (sender != recipient && interestRecipient != 0) { //handle special case of sender = recipient (no duplicate interest), ignore if interestRecipient = 0 (save gas)
            _mint(recipient, interestRecipient);
        }

        // transfer amounts
        super._transfer(sender, recipient, amount);
    }

    function _calculateInterest(uint256 _balance, uint256 _blockNumber) internal view returns (uint256 interest) {
        uint256 baseRate = 4; //4 percent
        uint256 _percentage = baseRate.mul(1e16).div(63072000).add(1e18); //1e16 maintains 0.04/63072000, scaled by 1e18

        if (block.number.sub(_blockNumber) > 0) { //exponential through a for loop
            uint256 _percentageNew = _percentage;
            for (uint i = 0; i < block.number.sub(_blockNumber).sub(1); i++) { //number of loops = difference in block - 1 (minus 1 because _percentage is already 1 block time)
                _percentageNew = _percentageNew.mul(_percentage).div(1e18); //divide by 1e18 to maintain 1e18 scaling
            }
            _percentage = _percentageNew;
        }


        if (block.number == _blockNumber) {
            _percentage = 1e18; //if calculated in the same block, interest is 1
        }

        return _balance.mul(_percentage).div(1e18).sub(_balance); //calculate new balance, remove scaling, subtract base amount to return interest amount
    }

    function _stake(uint256 amt) internal {
      s.deposit(amt);
    }

    function _unstake(uint256 amt) internal {
      s.withdraw(amt); //TODO: handle the case where amt (calculated with interest) is greater than staked amount

      //withdrawing from staking may withdraw more than sCFX. Return extra to staking pool
      if (address(this).balance > amt) {
        _stake(address(this).balance.sub(amt));
      }
    }

    function withdraw() external {
        uint256 balance = balanceOf(msg.sender); // get balances of sender + recipient

        uint interest = _calculateInterest(balance, _lastBlockCalc[msg.sender]); // calculate interest for sender + recipient

        _lastBlockCalc[msg.sender] = block.number; // update last block that calculation was run + interested was distributed

        _mint(msg.sender, interest); //distribute interest

        _unstake(balance.add(interest)); //unstake CFX

        _burn(msg.sender, balance.add(interest)); //burn tokens

        address(this).transfer(balance.add(interest)); // send tokens
    }

    receive() external payable {
        require(msg.value >= 1 ether, "minimum deposit = 1 CFX");

        // mint interest if there is a non-zero balance
        if (balanceOf(msg.sender) > 0) {
          uint256 interest = _calculateInterest(balanceOf(msg.sender), _lastBlockCalc[msg.sender]);
          _mint(msg.sender, interest);
        }

        _lastBlockCalc[msg.sender] = block.number; //set the latest block number
        _stake(msg.value); //stake the deposited tokens
        _mint(msg.sender, msg.value); //mint equivalent tokens
    }

    fallback() external {
        require(false, "fallback revert");
    }

}
