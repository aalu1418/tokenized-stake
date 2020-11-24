const { Conflux, Drip } = require("js-conflux-sdk");
const { abi } = require("../build/contracts/StakedCFX.json");
require("dotenv").config();

async function main() {
  const cfx = new Conflux({
    url: "http://test.confluxrpc.org",
    logger: console,
  });

  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const CONTRACT_ADDR = "0x88a5C110e12b9fff39102704f8AE1239E80Da12A";

  // ================================ Account =================================
  const account = cfx.wallet.addPrivateKey(PRIVATE_KEY); // create account instance

  // ================================ Contract ================================
  // create contract instance
  const contract = cfx.Contract({ abi, address: CONTRACT_ADDR });

  let receipt = await contract
    .withdraw()
    .sendTransaction({ from: account })
    .executed();
}

main().catch((e) => console.error(e));
