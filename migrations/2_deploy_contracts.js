var SafeMath = artifacts.require("./SafeMath.sol");
var usingOraclize = artifacts.require("./usingOraclize.sol");
var EcogyOracle = artifacts.require("./EcogyOracle.sol");
var Ecogy = artifacts.require("./Ecogy.sol");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(SafeMath);
  deployer.deploy(usingOraclize);
  deployer.deploy(EcogyOracle);
  deployer.deploy(Ecogy);
};