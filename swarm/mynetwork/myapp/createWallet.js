const helper = require('./helper')
const path = require('path')
const { Wallets } = require('fabric-network');

async function main() {

    try {
        var orgName = 'sas';
        const walletName = '/identity/wallet' + orgName;
        const walletPath = path.join(__dirname, walletName);
        const wallet = await helper.buildWallet(Wallets, walletPath);

        var orgName2 = 'quiron';
        const walletName2 = '/identity/wallet' + orgName2;
        const walletPath2 = path.join(__dirname, walletName2);
        const wallet2 = await helper.buildWallet(Wallets, walletPath2);

        var orgName3 = 'hla';
        const walletName3 = '/identity/wallet' + orgName3;
        const walletPath3 = path.join(__dirname, walletName3);
        const wallet3 = await helper.buildWallet(Wallets, walletPath3);

        var orgName4 = 'viamed';
        const walletName4 = '/identity/wallet' + orgName4;
        const walletPath4 = path.join(__dirname, walletName4);
        const wallet4 = await helper.buildWallet(Wallets, walletPath4);
    } catch (error) {
        console.log(`Error creating wallet. ${error}`);
        console.log(error.stack);
    }

}

main().then(() => {
    console.log('done');
}).catch((e) => {
    console.log(e);
    console.log(e.stack);
    process.exit(-1);
});