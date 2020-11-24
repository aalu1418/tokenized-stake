// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Staking.sol";

contract StakedCFX is ERC20 {
    mapping (address => uint256) private _lastBlockCalc;
    uint256 private baseRate = 4; //4 percent (staking yield)
    uint256 private _percentage = baseRate.mul(1e16).div(63072000).add(1e18); //1e16 maintains 0.04/63072000, scaled by 1e18
    uint256 private _percentage2 = _percentage.mul(_percentage).div(1e18); // squared term

    Staking internal s = Staking(0x0888000000000000000000000000000000000002);

    constructor() public payable ERC20("Staked CFX", "sCFX") {
      require(msg.value == 1e18, "must deploy with 1 CFX"); //deploy with 1 CFX to ensure tokens always can be restaked
    }

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
        uint256 _percentageCalc = 1e18; //starting with 1
        uint256 blockDiff = block.number.sub(_blockNumber);
        if (blockDiff > 0) { //exponentiation by squaring (is there a more efficient method?)
            uint256 loopNum = blockDiff.sub(blockDiff.mod(2)).div(2);
            // https://en.m.wikipedia.org/wiki/Exponentiation_by_squaring
            for (uint i = 0; i < loopNum; i++) {
                _percentageCalc = _percentageCalc.mul(_percentage2).div(1e18); //divide by 1e18 to maintain 1e18 scaling
            }

            if (blockDiff.mod(2) == 1) {
              _percentageCalc = _percentageCalc.mul(_percentage).div(1e18);
            }

            return _balance.mul(_percentageCalc).div(1e18).sub(_balance); //calculate new balance, remove scaling, subtract base amount to return interest amount
        } else {
            assert(blockDiff == 0);
            return 0; //return balance if block.number.sub(_blockNumber) = 0
        }

    }

    function _stake(uint256 amt) internal {
      s.deposit(amt);
    }

    function _unstake(uint256 amt) internal {
      // withdraw all tokens
      uint256 balance = s.getStakingBalance(address(this));
      s.withdraw(balance);

      // restake all tokens minus the amount to be returned
      assert(address(this).balance.sub(amt) >= 1e18); // balance will always be >= 1 CFX
      _stake(address(this).balance.sub(amt));
    }

    function withdraw() external {
        uint256 balance = balanceOf(msg.sender); // get balances of sender + recipient

        uint256 interest = _calculateInterest(balance, _lastBlockCalc[msg.sender]); // calculate interest for sender + recipient

        _lastBlockCalc[msg.sender] = block.number; // update last block that calculation was run + interested was distributed

        _mint(msg.sender, interest); //distribute interest

        _unstake(balance.add(interest)); //unstake CFX

        _burn(msg.sender, balance.add(interest)); //burn tokens

        address(this).transfer(balance.add(interest)); // send tokens
    }

    receive() external payable {
        require(msg.value >= 1e18, "minimum deposit = 1 CFX");

        // mint interest if there is a non-zero balance
        if (balanceOf(msg.sender) > 0) {
          uint256 interest = _calculateInterest(balanceOf(msg.sender), _lastBlockCalc[msg.sender]);
          _mint(msg.sender, interest);
        }

        _lastBlockCalc[msg.sender] = block.number; //set the latest block number
        _stake(address(this).balance); //stake all deposited tokens
        _mint(msg.sender, msg.value); //mint equivalent tokens
    }
}
