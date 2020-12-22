const StakedCFX = artifacts.require("StakedCFX");
const { Drip } = require("js-conflux-sdk");
const truffleAssert = require("truffle-assertions");

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

contract("StakedCFX", async (accounts) => {
  const [initialHolder, recipient, anotherAccount] = accounts;

  it("contract deploys", async () => {
    this.token = await StakedCFX.deployed();
  });

  it('named "Staked CFX"', async () => {
    assert.equal(await this.token.name(), "Staked CFX");
  });

  it('symbol "sCFX"', async () => {
    assert.equal(await this.token.symbol(), "sCFX");
  });

  it("uses 18 decimals", async () => {
    assert.equal(await this.token.decimals(), "18");
  });

  let block0;
  it("CFX deposit creates equivalent token amounts", async () => {
    const amount = 10000000000000000000;
    const tx = await this.token.sendTransaction({
      from: initialHolder,
      value: amount,
    });

    block0 = tx.receipt.blockNumber;

    // check event
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == ZERO_ADDRESS && ev.to == initialHolder;
    });

    // check token minting balance
    const balance = await this.token.balanceOf(initialHolder);
    assert.equal(String(amount), balance.toString());
  });

  it("CFX deposit reverts if less than 1 CFX", async () => {
    const amount = 100000000000000000;
    await truffleAssert.reverts(
      this.token.sendTransaction({
        from: initialHolder,
        value: amount,
      }),
      "minimum deposit = 1 CFX"
    );
  });

  it("interest calculates within tolerance", async () => {
    const tx = await this.token.transfer(initialHolder, 0, {
      from: initialHolder,
    });
    const blockDiff = tx.receipt.blockNumber - block0;
    const balance = await this.token.balanceOf(initialHolder);
    const balanceDiff = balance.toString() - 10000000000000000000;

    const expectedInterest = Math.round(
      10000000000000000000 * ((1 + 0.04 / 63072000) ** blockDiff - 1)
    );
    assert.isBelow(
      Math.abs(expectedInterest - balanceDiff),
      5000,
      "formula calculation variance is under 5e3"
    );
  });

  it("transfers tokens to new sCFX holder and deposits interest", async () => {
    const amount = "1000000000000000000";
    const balanceInit = await this.token.balanceOf(initialHolder);

    const tx = await this.token.transfer(recipient, amount, {
      from: initialHolder,
    });

    // accumulated interest
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == ZERO_ADDRESS && ev.to == initialHolder;
    });

    // transfer amount
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == initialHolder && ev.to == recipient;
    });

    // no extra interest minted
    truffleAssert.eventNotEmitted(tx, "Transfer", (ev) => {
      return ev.from == ZERO_ADDRESS && ev.to == recipient;
    });

    assert.equal(2, tx.logs.length, "only two logs emitted")

    // check token transfer balance
    const balance = await this.token.balanceOf(recipient);
    assert.equal(amount, balance.toString(), "recipient recieved amount");

    // check token transfer balance
    const balanceFinal = await this.token.balanceOf(initialHolder);
    assert.isAbove(Number(amount), balanceInit-balanceFinal, "sender recieved interest")
  });

  it("transfers tokens to existing sCFX holder and deposits interest", async () => {
    const amount = "1000000000000000000";
    const balanceInit = await this.token.balanceOf(initialHolder);
    const balanceInitRecip = await this.token.balanceOf(recipient);

    const tx = await this.token.transfer(recipient, amount, {
      from: initialHolder,
    });

    // accumulated interest
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == ZERO_ADDRESS && ev.to == initialHolder;
    });

    // transfer amount
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == initialHolder && ev.to == recipient;
    });

    // no extra interest minted
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == ZERO_ADDRESS && ev.to == recipient;
    });

    assert.equal(3, tx.logs.length, "only three logs emitted")

    // check token transfer balance
    const balanceFinalRecip = await this.token.balanceOf(recipient);
    assert.isAbove(balanceFinalRecip-balanceInitRecip, Number(amount), "recipient recieved amount + interest");

    // check token transfer balance
    const balanceFinal = await this.token.balanceOf(initialHolder);
    assert.isAbove(Number(amount), balanceInit-balanceFinal, "sender recieved interest")
  })

  it("transfer to self does not duplicate interest tokens", async () => {
    // using recipient user to establish the storage staking (so it won't affect the withdraw calculations)
    const tx = await this.token.transfer(recipient, 0, {
      from: recipient,
    });

    // accumulated interest
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == ZERO_ADDRESS && ev.to == recipient;
    });

    // transfer amount
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == recipient && ev.to == recipient;
    });

    assert.equal(2, tx.logs.length, "only two logs emitted")
  });

  it("can withdraw CFX tokens from sCFX", async () => {
    const cfxBalance = await web3.cfx.getBalance(recipient);
    const tokenBalance = await this.token.balanceOf(recipient);

    assert.notEqual(0, tokenBalance, "user has balance")

    //setting minimal gas fee for testing to minimize impact of gas on returned value
    const tx = await this.token.withdraw({from: recipient, gasPrice: "0x1"});

    // mint interest
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == ZERO_ADDRESS && ev.to == recipient;
    });

    // burn all tokens
    truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
      return ev.from == recipient && ev.to == ZERO_ADDRESS;
    });

    assert.equal(2, tx.logs.length, "only two logs emitted")

    const cfxBalanceEnd = await web3.cfx.getBalance(recipient);
    const tokenBalanceEnd = await this.token.balanceOf(recipient);

    assert.equal(0, tokenBalanceEnd.toString(), "all balance withdrawn")
    assert.isAbove(Number(cfxBalanceEnd-cfxBalance), Number(tokenBalance), "sCFX converted to CFX + interest")
  });

  it("all CFX is withdrawable", async () => {
    const totalSupplyInit = await this.token.totalSupply();
    assert.notEqual(Number(totalSupplyInit), 0, "total supply is not zero")

    await truffleAssert.passes(this.token.withdraw(), "tokens from initial holder withdrawn");

    const totalSupply = await this.token.totalSupply();
    assert.equal(Number(totalSupply), 0, "final total supply is zero")
  });
});
