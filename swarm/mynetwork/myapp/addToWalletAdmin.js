const caActions = require('./caActions')

  // Adds admin and one user for each org to the org wallet

async function main() {

    try {
        // Sas
        var orgName = 'sas';
        await caActions.getAdmin(orgName);

        // Quiron
        orgName = 'quiron';
        await caActions.getAdmin(orgName);

        // Hla
        orgName = 'hla';
        await caActions.getAdmin(orgName);


        // Viamed
        orgName = 'viamed';
        await caActions.getAdmin(orgName);

    } catch (error) {
        console.log(`Error adding to wallet. ${error}`);
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
