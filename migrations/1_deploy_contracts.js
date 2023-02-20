
const Staking = artifacts.require("Bytrade_Staking");

module.exports = async function(deployer) {
  deployer.deploy(Staking, "0x95670D1f6baa0E78bcfe887Bde51FeC9Cc58230F");
};
