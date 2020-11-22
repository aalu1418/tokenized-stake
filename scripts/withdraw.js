const { Conflux, Drip } = require("js-conflux-sdk");
const { abi } = require("../build/contracts/StakedCFX.json");
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

  // ================================ Contract ================================
  // create contract instance
  const contract = cfx.Contract({ abi, address: CONTRACT_ADDR });

  let receipt = await contract
    .withdraw()
    .sendTransaction({ from: account })
    .executed();
}

main().catch((e) => console.error(e));
