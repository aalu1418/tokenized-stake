const StakedCFX = artifacts.require("StakedCFX");

module.exports = function(deployer) {
  deployer.deploy(StakedCFX);
};
