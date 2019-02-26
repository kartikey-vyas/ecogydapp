var SafeMath = artifacts.require("./SafeMath.sol");
var usingOraclize = artifacts.require("./usingOraclize.sol");
var EcogyOracle = artifacts.require("./EcogyOracle.sol");
var Ecogy = artifacts.require("./Ecogy.sol");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(SafeMath);
  deployer.deploy(usingOraclize);
  deployer.deploy(EcogyOracle);
  deployer.deploy(Ecogy, {
    from: accounts[0],
    gas: 6721975,
    value: 500000000000000000
  });
};