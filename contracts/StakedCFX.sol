pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract StakedCFX is ERC20 {
    mapping (address => uint256) private _blockTime;

    constructor(uint256 initialSupply) public ERC20("Staked CFX", "sCFX") {
        _mint(msg.sender, initialSupply);
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        //todo: implement minting interest tokens
        super._transfer(sender, recipient, amount);
    }
    
    
    function _calculateInterest(uint256 _balance, uint256 _blockNumber) internal view returns (uint256 interest) {
        uint256 baseRate = 4;
        uint256 _percentage = baseRate.mul(1e16).div(63072000).add(1e18);
        
        if (block.number.sub(_blockNumber) > 0) {
            uint256 _percentageNew = _percentage;
            for (uint i = 0; i < block.number.sub(_blockNumber).sub(1); i++) {
                _percentageNew = _percentageNew.mul(_percentage).div(1e18);
            }
            _percentage = _percentageNew;
        }
        
        
        if (block.number == _blockNumber) {
            _percentage = 1e18;
        }
        
        return _balance.mul(_percentage).div(1e18).sub(_balance);
    }
    
    //todo: implement deposit + withdraw interfaces
}

