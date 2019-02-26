# Ecogy Dapp
core Dependencies:

    Truffle v5.0.5
    Solidity v0.5.0
    Node v10.15.1

command to install npm dependencies properly:
    
    sudo npm install *package* --unsafe-perm=true --allow-root
    
This was required for web3 and a few other packages (node-gyp reuild error)

As of Tuesday, 26 February 2019, the final version of the Ecogy Dapp code will be backed up here. The original repository for all the code used in development can be found at:
    https://github.com/kartikey-vyas/ecogy-smart-contract

In this repo, I have made sure to use the latest versions of solidity, truffle and any associated packages or frameworks required for the dapp.

Description and user guide coming soon...

### Ecogy Contract features (processes that occur on the blockchain itself):
    - store project data
    - store investor data
    - create new project (only callable by contract creator)
    - delete project (unstable, don't use this outside of VM or local dev chain)
    - invest in project with ether
    - sell project shares for ether
    - update wattHours using oraclize
    - calculate ROI from wattHours (currently callable once a month);
    - send ROI to investors


useful repo to model this project on: https://github.com/shawntabrizi/Ethereum-Twitter-Bounty

#### Free Test Ether
metamask seed phrase: 

    rose essence remain logic confirm toast chunk twist space fragile body hip

metamask ropsten testnet account address:

    0x4e2da50a65a4a2d68a898df0c6c94dd8c92348e1
    private key: a55428ae7da1352934a3f1c7a93e0cc37f8c45860ce3a00ba1d3855913e8a770


retrieve 1 test ether everyday from https://faucet.ropsten.be/