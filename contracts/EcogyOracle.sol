pragma solidity ^0.5.0;

import "./usingOraclize.sol";

contract EcogyOracle is usingOraclize {
    uint public wattHours;
    uint rate = 1000 wei;
    uint earningpershare;
    
    
    event NewOraclizeQuery(string description);
    event NewWattHours(string wattHours);
    
    constructor() public {
        update();
    }
    
    function __callback(bytes32 queryId, string memory result) public {
        if(msg.sender != oraclize_cbAddress()) revert("callback received from incorrect address");
        wattHours = parseInt(result);
        emit NewWattHours(result);
        earningpershare = rate * wattHours;
    }
    
    function get() public view returns (uint, uint) {
        return (earningpershare, wattHours);
    }
    
    function update() public payable {
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit NewOraclizeQuery("Oraclize query was sent, waiting for a response");
            oraclize_query("URL", "json(https://data.solarnetwork.net/solarquery/api/v1/pub/datum/mostRecent?nodeId=338).data.results[0].wattHours");
        }
    }
}