# Tokenized Stake + Interest Bearing CFX

Using Conflux Network staking to create interest-bearing wrapped CFX in the ERC-20 token standard.

Testnet deployed address: [0x890cE2348eD62C0DF79eB0d81b0c7C3aCD103670](https://testnet.confluxscan.io/address/0x890ce2348ed62c0df79eb0d81b0c7c3acd103670)

**NOTE: This project is not audited. It is simply a demonstration of an idea for building on Conflux.**

## Interactions
* Basic ERC-20 functionality (`balanceOf`, `transfer`, `transferFrom`, `approve`, `allowance`, `totalSupply`)
* `receive` is the default fallback for depositing CFX to convert into sCFX. To interact, send greater than 1 CFX to contract address.
* `withdraw` is called when converting sCFX to CFX. It withdraws all of a users sCFX.

## Developer Notes
THe base of the smart contract is the [Open Zeppelin ERC-20](https://docs.openzeppelin.com/contracts/2.x/api/token/erc20) template in order to start from a audited and prove-secure contract.

The main modifications are as follows (+ associated functionality for calculating interest, staking, unstaking):
* Intermediary step for the `_transfer()` function to calculate interest and mint interest for the sender and recipient before calling the origin `_transfer()` function
* Fallback function `receive()` for receiving deposits to convert CFX into sCFX
* `withdraw()` function that allows a user to convert all their sCFX into CFX

When deploying, 1 CFX is deposited into the contract to make sure withdraws can always be processed (there is always 1 CFX that can be staked).

Uses [Conflux Truffle](https://www.npmjs.com/package/conflux-truffle) and the Conflux docker image.

### Improvements:
* Better + more complete test cases
* More efficient interest calculation (values are currently hard coded in a way to create a binary search for calculating interest)
* Withdraw function for specific amounts instead of all
* Mechanism to deposit less than 1 CFX

### Local Testing
Start Docker image:
```
docker pull confluxchain/conflux-rust
docker run -p 12537:12537 --name cfx-node confluxchain/conflux-rust
```

Run test cases:
```
cfxtruffle test
```
Test cases are using the built in Mocha/Chai testing framework [Truffle Assertions](https://www.npmjs.com/package/truffle-assertions)

Clear docker image:
```
docker kill cfx-node
docker rm cfx-node
```

## Testnet Deployment
Command to deploy to testnet:
```
cfxtruffle deploy --network testnet
```

`.env` file setup:
```
PRIVATE_KEY=<insert private key here>
```

Current testnet deployment:
```
1_deploy.js
===========

   Replacing 'StakedCFX'
   ---------------------
   > transaction hash:    0x11189da87f7e39b4b340cce3e04583ca5f6e95d810198062571b828bda2b1689
   > Blocks: 4            Seconds: 4
   > contract address:    0x890cE2348eD62C0DF79eB0d81b0c7C3aCD103670
   > block number:        3716174
   > block timestamp:     1606575225
   > account:             0x15fd1E4F13502b1a8BE110F100EC001d0270552d
   > balance:             354.341266202675765994
   > gas used:            2755284 (0x2a0ad4)
   > gas price:           20 GDrip
   > value sent:          1 CFX
   > total cost:          1.05510568 CFX

   > Saving artifacts
   -------------------------------------
   > Total cost:          1.05510568 CFX


Summary
=======
> Total deployments:   1
> Final cost:          1.05510568 CFX

```
