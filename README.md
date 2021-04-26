# Ecogy Dapp

As of Tuesday, 26 February 2019, the final version of the Ecogy Dapp code will be backed up here. The original repository for all the code used in development can be found at:
    https://github.com/kartikey-vyas/ecogy-smart-contract

In this repo, I have made sure to use the latest versions of solidity, truffle and any associated packages or frameworks required for the dapp.

Description and user guide coming soon...

core Dependencies:

    Truffle v5.0.5
    Solidity v0.5.0
    Node v10.15.1

command to install npm dependencies properly:

    sudo npm install *package* --unsafe-perm=true --allow-root
    
This was required for web3 and a few other packages (node-gyp reuild error)


#### Free Test Ether

retrieve 1 test ether everyday from https://faucet.ropsten.be/



### Current State of the Dapp
#### Backend
##### Ecogy Contract features (processes that occur on the blockchain itself):
    - store project data
    - store investor data
    - create new project (only callable by contract creator)
    - delete project (unstable, don't use this outside of VM or local dev chain)
    - invest in project with ether
    - sell project shares for ether
    - update wattHours using oraclize
    - calculate ROI from wattHours (currently callable once a month);
    - send ROI to investors

##### Recommendations
The solidity contracts are effectively finished in terms of functionality.

To improve the flexibility and security of the contracts, consider using the OpenZeppelin library (https://github.com/OpenZeppelin/openzeppelin-solidity)
This library contains interfaces and contracts to inherit from that allow utility such as:
    - pausability
    - ownability
    - security features (e.g. reentrancy guard)
    - resources to implement an ERC-20 token(s)
    - crowdsale contracts
for simple examples of how these are used and what advantages they can provide, see this project: https://github.com/shawntabrizi/Ethereum-Twitter-Bounty

#### Frontend
##### Client-side app features
The website that I've built for our smart contract has UI elements to call most of the functions in the smart contract from the browser.

Frameworks used: Truffle (compiling, testing, migrating)
js packages used: - truffle-contract (for easier contract abstraction)
                  - web3 1.0.0 beta-37 (for infura websocket provider, this is needed for event listening on the ropsten testnet or any other live blockchain)
                  - jquery (for bootstrap 4 and DOM manipulation)

###### behaviour on local chain
    - Deployed on local memory blockchain (ganache gui/ganache-cli/truffle develop)
    - using metamask in the browser to sign transcations
    - injected web3 instance
    - ethereum bridge running locally

UI elements to create, delete, invest, sell shares, view investments and update solarnetwork data.

responds to events in real time
    currently only the InvestmentMade() event is being listened to for UI refreshing.
    Similar logic can be applied to ProjectCreated() and NewOraclizeQuery() etc to make the UI more responsive.

###### behaviour on ropsten
    - deployed through infura node
    - uses metamask to sign transactions
    - injected web3 instance for truffle-contract
    - separate websocket web3 instance for event listening on infura

UI event listening works, but due to block mining times refreshing doesn't happen when its supposed to.

##### Recommendations
implement UI elements that call calculateReturn() and sendROI()
investigate alternatives to truffle-contract
    - keep in the loop with /r/ethdev to find new tools as they are released
look at creating a login system for Ecogy (owner) and investors
pull in details about each project




## How to set up a test environment (local)

1. make sure you have these things installed globally

    npm install -g truffle
    npm install -g ganache
    npm install -g lite-server
    npm install -g ethereum-bridge

2. launch ethereum bridge

    node bridge -a 9 -H 127.0.0.1 -p 7545 --dev

3. launch the ganache gui
4. In a new terminal, navigate to the project directory and compile and migrate the contracts
    
    truffle compile
    truffle migrate --reset

5. launch the web app

    lite-server

