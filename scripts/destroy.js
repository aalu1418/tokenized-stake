const { Conflux, Drip } = require("js-conflux-sdk");
require("dotenv").config();

async function main() {
  const cfx = new Conflux({
    url: "http://test.confluxrpc.org",
    logger: console,
  });

  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const CONTRACT_ADDR = "0x8Ef9451fEAf9d713091a9E9A88FC0280b4F67a41";

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
