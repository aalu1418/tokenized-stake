const { Conflux, Drip } = require("js-conflux-sdk");
const { abi } = require("../build/contracts/StakedCFX.json");
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

  // ================================ Contract ================================
  // create contract instance
  const contract = cfx.Contract({ abi, address: CONTRACT_ADDR });

  let receipt = await contract
    .withdraw()
    .call({ from: account })
}

main().catch((e) => console.error(e));
