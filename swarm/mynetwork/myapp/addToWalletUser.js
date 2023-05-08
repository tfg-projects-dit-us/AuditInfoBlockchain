const caActions = require('./caActions')

  // Adds admin and one user for each org to the org wallet

async function main() {

    try {
        // Sas
        var orgName = 'sas';
        var userName = 'sasuser';
        await caActions.getUser(userName, orgName);

        // Quiron
        orgName = 'quiron';
        userName = 'quironuser';
        await caActions.getUser(userName, orgName);

        // Hla
        orgName = 'hla';
        userName = 'hlauser';
        await caActions.getUser(userName, orgName);


        // Viamed
        orgName = 'viamed';
        userName = 'viameduser';
        await caActions.getUser(userName, orgName);

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

