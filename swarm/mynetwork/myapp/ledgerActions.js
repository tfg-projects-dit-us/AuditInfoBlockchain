/**
 * Ledger - Actions
 */

// node.js includes
const helper = require('./helper')
const path = require('path')

// fabric includes
const { Gateway, Wallets } = require('fabric-network');

// some vars
const channelName = 'mychannel';
const chaincodeName = 'smartcontract';

/**
 * Invoke transaction
 * @param {*} orgName  
 * @param {*} UserId 
 * @param {*} fun 
 * @param {*} data
 */

exports.invoke = async function (orgName, UserId, identifier, idOrgS, nameOrgS, idOrgD, nameOrgD, validityDate, idPatient, purpose, recorded) {
  try {
    let result;
    // build CCP
    const ccp = helper.buildCCP(orgName);
    
    // setup the wallet to hold the credentials of the application user
    const walletName = '/identity/wallet' + orgName;
    const walletPath = path.join(__dirname, walletName);
    const wallet = await helper.buildWallet(Wallets, walletPath);

    console.log('antes de get');
    let identity = wallet.get(UserId);
    console.log('después de get');
    if (!identity) {
      result = 'Error. An identity for the user ' + UserId + ' does not exist in the wallet.';
      console.log(result);
      return result;
    }
    else {

      // Create a new gateway instance for interacting with the fabric network.
      // In a real application this would be done as the backend server session is setup for
      // a user that has been verified.
      const gateway = new Gateway();
        
      // setup the gateway instance
      // The user will now be able to create connections to the fabric network and be able to
      // submit transactions and query. All transactions submitted by this gateway will be
      // signed by this user using the credentials stored in the wallet.
      console.log('antes de connect');
      await gateway.connect(ccp, {
        wallet,
        identity: UserId,
        discovery: { enabled: true, asLocalhost: false } // using asLocalhost as this gateway is using a fabric network deployed locally
      });
      console.log('después de connect');

      // Build a network instance based on the channel where the smart contract is deployed
      const network = await gateway.getNetwork(channelName);

      // Get the contract from the network.
      const contract = network.getContract(chaincodeName);

      // const identifier = data[0];
      // const idOrgS = data[1];
      // const nameOrgS = data[2];
      // const idOrgD = data[3];
      // const nameOrgD = data[4];
      // const validityDate = data[5];
      // const idPatient = data[6];
      // const purpose = data[7];
      // const recorded = data[8];
      result = await contract.submitTransaction('newTransaction', identifier, idOrgS, nameOrgS, idOrgD, nameOrgD, validityDate, idPatient, purpose, recorded);
      console.log('*** Result: committed', result.toString());

      // disconnect form the network
      gateway.disconnect();

      return 'Transaction commited correctly.';
    }
  }
  catch(e){
    result = 'Error. ' + e.message;
    return result;
  }   
}

/**
 * Query ledger
 * @param {*} orgName  
 * @param {*} UserId 
 * @param {*} fun 
 * @param {*} data
 */

exports.query = async function (orgName, UserId, fun, data) {
  try {
    let result;
    // build CCP
    const ccp = helper.buildCCP(orgName);
    
    // setup the wallet to hold the credentials of the application user
    const walletName = '/identity/wallet' + orgName;
    const walletPath = path.join(__dirname, walletName);
    const wallet = await helper.buildWallet(Wallets, walletPath);

    let identity = wallet.get(UserId);
    if (!identity) {
      result = 'Error. An identity for the user ' + UserId + ' does not exist in the wallet.';
      console.log(result);
      return result;
    }
    else {

      // Create a new gateway instance for interacting with the fabric network.
      const gateway = new Gateway();
        
      // setup the gateway instance
      await gateway.connect(ccp, {
        wallet,
        identity: UserId,
        discovery: { enabled: true, asLocalhost: false } 
      });

      // Build a network instance based on the channel where the smart contract is deployed
      const network = await gateway.getNetwork(channelName);

      // Get the contract from the network.
      const contract = network.getContract(chaincodeName);

      if(fun === 'readBySource'){
        let sOrg = data
        result = await contract.evaluateTransaction('readBySource', sOrg);
        console.log(`${helper.prettyJSONString(result.toString())}`);
      } 
      else if(fun === 'readByDestination'){
        let dOrg = data
        result = await contract.evaluateTransaction('readByDestination', dOrg);
        console.log(`${helper.prettyJSONString(result.toString())}`);
      }
      else if(fun === 'readByDate'){
        let date = data
        result = await contract.evaluateTransaction('readByDate', date);
        console.log(`${helper.prettyJSONString(result.toString())}`);
      }
      else if(fun === 'readByPatient'){
        let idPatient = data
        result = await contract.evaluateTransaction('readByPatient', idPatient);
        console.log(`${helper.prettyJSONString(result.toString())}`);
      }
      else if(fun === 'readAll'){
        result = await contract.evaluateTransaction('readAll');
        console.log(`${helper.prettyJSONString(result.toString())}`);
      }
      else {
        console.log('...')
        result = 'Error';
      }
      // disconnect form the network
      gateway.disconnect();

      return result.toString();;
    }
  }
  catch(e){
    result = 'Error. ' + e.message;
    return result;
  }   
}


