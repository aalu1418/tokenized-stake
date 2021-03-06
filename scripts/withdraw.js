const { Conflux, Drip } = require("js-conflux-sdk");
const { abi } = require("../build/contracts/StakedCFX.json");
require("dotenv").config();

async function main() {
  const cfx = new Conflux({
    url: "http://test.confluxrpc.org",
    logger: console,
  });

  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const CONTRACT_ADDR = "0x890cE2348eD62C0DF79eB0d81b0c7C3aCD103670";

  // ================================ Account =================================
  const account = cfx.wallet.addPrivateKey(PRIVATE_KEY); // create account instance

  // ================================ Contract ================================
  // create contract instance
  const contract = cfx.Contract({ abi, address: CONTRACT_ADDR });

  let receipt = await contract
    .withdraw()
    .sendTransaction({ from: account })
    .executed();

  // await cfx
  //   .sendTransaction({
  //     from: account,
  //     to: CONTRACT_ADDR,
  //     value: Drip.fromCFX(1),
  //     gas: "15000000",
  //   })
  //   .executed();
}

main().catch((e) => console.error(e));
