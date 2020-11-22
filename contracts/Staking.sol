pragma solidity >=0.4.15;

// https://github.com/Conflux-Chain/conflux-rust/blob/master/internal_contract/contracts/Staking.sol

contract Staking {
    /*** Query Functions ***/
    /**
     * @dev get user's staking balance
     * @param user The address of specific user
     */
    function getStakingBalance(address user) public view returns (uint) {}

    /**
     * @dev get user's locked staking balance at given blockNumber
     * @param user The address of specific user
     * @param blockNumber The blockNumber as index.
     */
    // ------------------------------------------------------------------------
    // Note: if the blockNumber is less than the current block number, function
    // will return current locked staking balance.
    // ------------------------------------------------------------------------
    function getLockedStakingBalance(address user, uint blockNumber) public view returns (uint) {}


    /**
     * @dev get user's vote power staking balance at given blockNumber
     * @param user The address of specific user
     * @param blockNumber The blockNumber as index.
     */
    // ------------------------------------------------------------------------
    // Note: if the blockNumber is less than the current block number, function
    // will return current vote power.
    // ------------------------------------------------------------------------
    function getVotePower(address user, uint blockNumber) public view returns (uint) {}

    function deposit(uint amount) external {}

    function withdraw(uint amount) external {}

    function voteLock(uint amount, uint unlockBlockNumber) external {}
}
