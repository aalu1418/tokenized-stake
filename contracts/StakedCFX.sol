// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
        _interest[0] = 1000000000634195839;
        _interest[1] = 1000000001268391679;
        _interest[2] = 1000000002536783361;
        _interest[3] = 1000000005073566728;
        _interest[4] = 1000000010147133483;
        _interest[5] = 1000000020294267069;
        _interest[6] = 1000000040588534550;
        _interest[7] = 1000000081177070747;
        _interest[8] = 1000000162354148084;
        _interest[9] = 1000000324708322528;
        _interest[10] = 1000000649416750492;
        _interest[11] = 1000001298833922727;
        _interest[12] = 1000002597669532423;
        _interest[13] = 1000005195345812734;
        _interest[14] = 1000010390718617087;
        _interest[15] = 1000020781545201209;
        _interest[16] = 1000041563522275039;
        _interest[17] = 1000083128772076462;
        _interest[18] = 1000166264454545671;
        _interest[19] = 1000332556552960188;
        _interest[20] = 1000665223699781293;
        _interest[21] = 1001330889922133336;
        _interest[22] = 1002663551112251509;
        _interest[23] = 1005334196729030595;
        _interest[24] = 1010696847112805192;
        _interest[25] = 1021508116763765113;
        _interest[26] = 1043478832614253980;
        _interest[27] = 1088848074114006277;
        _interest[28] = 1185590128501780506;
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

    function _calculateInterest(uint256 _balance, uint256 blockDiff) internal view returns (uint256 interest) {
        if (blockDiff > 0) {
            //exponentiation using binary search (offload computation as much as possible)
            uint256 _percentageCalc = 1e18; //starting with 1

            for (uint256 i = 0; i < twos.length; i++) { //start checking with largest interval
                uint256 ind = twos.length.sub(1).sub(i);
                uint256 twosVal = twos[ind];
                uint256 blockDiff_new = blockDiff.mod(twosVal); //calculate remaining exponent

                // apply precalculated interest of current exponent (if there was a change)
                if (blockDiff != blockDiff_new) {
                    uint256 loopMax = blockDiff.sub(blockDiff_new).div(twosVal);
                    for (uint256 j = 0; j < loopMax; j++) {
                        _percentageCalc = _percentageCalc.mul(_interest[ind]).div(1e18);
                    }
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
      require(address(this).balance.sub(amt) >= 1e18, "base amount must be >= 1 CFX"); // balance will always be >= 1 CFX
      _stake(address(this).balance.sub(amt));
    }

    function withdraw() external {
        uint256 balance = balanceOf(msg.sender); // get balances of sender + recipient

        uint256 interest = _calculateInterest(balance, block.number.sub(_lastBlockCalc[msg.sender])); // calculate interest for sender + recipient

        _lastBlockCalc[msg.sender] = block.number; // update last block that calculation was run + interested was distributed

        _mint(msg.sender, interest); //distribute interest

        _unstake(balance.add(interest)); //unstake CFX

        _burn(msg.sender, balance.add(interest)); //burn tokens

        msg.sender.transfer(balance.add(interest)); // send CFX to msg.sender
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
