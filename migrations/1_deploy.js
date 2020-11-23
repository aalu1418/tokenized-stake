const StakedCFX = artifacts.require("StakedCFX");
const { Drip } = require("js-conflux-sdk");

module.exports = function (deployer) {
  deployer.deploy(StakedCFX, { value: String(Drip.fromCFX(1)) });
};
