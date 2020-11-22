const { Conflux, Drip } = require("js-conflux-sdk");
require("dotenv").config();

async function main() {
  const cfx = new Conflux({
    url: "http://test.confluxrpc.org",
    logger: console,
  });

  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const CONTRACT_ADDR = "0x81878de694288b339C88f375CE65Dcf39B9fa1d0";

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
