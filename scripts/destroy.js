const { Conflux, Drip } = require("js-conflux-sdk");
require("dotenv").config();

async function main() {
  const cfx = new Conflux({
    url: "http://test.confluxrpc.org",
    logger: console,
  });

  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const CONTRACT_ADDR = "0x8ec4b4816de6551e8495134eff72d3b9e53b381c";

  // ================================ Account =================================
  const account = cfx.wallet.addPrivateKey(PRIVATE_KEY); // create account instance
  console.log("Admin Address:", account.address); //sponsor account

  // ================================ Contract ================================
  // create contract instance
  const contract = cfx.InternalContract("AdminControl");

  let receipt = await contract
    .destroy(CONTRACT_ADDR)
    .sendTransaction({ from: account })
    .executed();
  console.log("Added Sponsored:", receipt);
}

main().catch((e) => console.error(e));
