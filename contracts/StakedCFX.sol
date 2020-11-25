// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Staking.sol";

contract StakedCFX is ERC20 {
    mapping (address => uint256) private _lastBlockCalc;
    mapping (uint256 => uint256) internal _interest;

    //offline 2^n calculations
    uint256[] internal twos = [1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576,2097152,4194304,8388608,16777216,33554432,67108864,134217728,268435456];

    Staking internal s = Staking(0x0888000000000000000000000000000000000002);

    constructor() public payable ERC20("Staked CFX", "sCFX") {
      require(msg.value == 1e18, "must deploy with 1 CFX"); //deploy with 1 CFX to ensure tokens always can be restaked
         // offline interest rate calculations for (1+0.04/63072000)^(2^n)*1e18
        _interest[0] = 10000000006341958396;
        _interest[1] = 10000000012683916797;
        _interest[2] = 10000000025367833611;
        _interest[3] = 10000000050735667286;
        _interest[4] = 10000000101471334830;
        _interest[5] = 10000000202942670691;
        _interest[6] = 10000000405885345500;
        _interest[7] = 10000000811770707475;
        _interest[8] = 10000001623541480848;
        _interest[9] = 10000003247083225285;
        _interest[10] = 10000006494167504925;
        _interest[11] = 10000012988339227271;
        _interest[12] = 10000025976695324239;
        _interest[13] = 10000051953458127348;
        _interest[14] = 10000103907186170878;
        _interest[15] = 10000207815452012091;
        _interest[16] = 10000415635222750391;
        _interest[17] = 10000831287720764622;
        _interest[18] = 10001662644545456713;
        _interest[19] = 10003325565529601881;
        _interest[20] = 10006652236997812930;
        _interest[21] = 10013308899221333368;
        _interest[22] = 10026635511122515097;
        _interest[23] = 10053341967290305958;
        _interest[24] = 10106968471128051923;
        _interest[25] = 10215081167637651134;
        _interest[26] = 10434788326142539808;
        _interest[27] = 10888480741140062773;
        _interest[28] = 11855901285017805069;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        // get balances of sender + recipient
        uint256 balanceSender = balanceOf(sender);
        uint256 balanceRecipient = balanceOf(recipient);

        // calculate interest for sender + recipient
        uint interestSender = _calculateInterest(balanceSender, block.number.sub(_lastBlockCalc[sender]));
        uint interestRecipient = 0; //interest = 0 (special case when recipient has never had tokens or currently has none)
        if (_lastBlockCalc[sender] != 0 || balanceRecipient != 0) {
            interestRecipient= _calculateInterest(balanceRecipient, block.number.sub(_lastBlockCalc[sender])); //otherwise calculate
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

    function _calculateInterest(uint256 _balance, uint256 blockDiff) public view returns (uint256 interest) {
        if (blockDiff > 0) {
            //exponentiation using binary search (offload computation as much as possible)
            uint256 _percentageCalc = 1e18; //starting with 1

            for (uint256 i = twos.length; i > 0; i--) { //start checking with largest interval
                uint256 blockDiff_new = blockDiff.mod(twos[i.sub(1)]); //calculate remaining exponent

                // apply precalculated interest of current exponent (if there was a change)
                for (uint256 j = 0; j < blockDiff.sub(blockDiff_new).div(twos[i.sub(1)]); j++) {
                    _percentageCalc = _percentageCalc.mul(_interest[i.sub(1)]).div(1e18);
                }

                // if no exponent left, break. Else, reset + continue
                if (blockDiff_new == 0) {
                    break;
                } else {
                    blockDiff = blockDiff_new;
                }
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

        uint256 interest = _calculateInterest(balance, block.number.sub(_lastBlockCalc[msg.sender])); // calculate interest for sender + recipient

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
          uint256 interest = _calculateInterest(balanceOf(msg.sender), block.number.sub(_lastBlockCalc[msg.sender]));
          _mint(msg.sender, interest);
        }

        _lastBlockCalc[msg.sender] = block.number; //set the latest block number
        _stake(address(this).balance); //stake all deposited tokens
        _mint(msg.sender, msg.value); //mint equivalent tokens
    }
}
