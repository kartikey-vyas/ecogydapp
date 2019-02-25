var SafeMath = artifacts.require("./SafeMath.sol");
var Oraclize = artifacts.require("./Oraclize.sol");
var EcogyOracle = artifacts.require("./EcogyOracle.sol");
var Ecogy = artifacts.require("./Ecogy.sol");

module.exports = function (deployer) {
  deployer.deploy(SafeMath);
  deployer.deploy(Oraclize);
  deployer.deploy(EcogyOracle);
  deployer.deploy(Ecogy);
};