var express = require('express');
var bodyParser = require('body-parser');
var fs = require('fs');
var https = require('https');
var cors = require('cors');
const jwt = require("jsonwebtoken")
var Nanoid = require('nanoid');
const caActions = require('./caActions')
const ledgerActions = require('./ledgerActions')

const PORT = 4000;
const jwtKey = "my_secret_key"
const jwtExpirySeconds = 3600

var app = express();
app.use(function (req, res, next) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.setHeader('Access-Control-Allow-Credentials', true);
  next();
});
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cors());


https.createServer({
  key: fs.readFileSync('cert/key.pem'),
  cert: fs.readFileSync('cert/cert.pem'),
  passphrase: 'tfgmgb16'
},app).listen(PORT, function(){
 console.log('Https server running on port ' + PORT);
});

app.post('/login', async function (req, res) {
  var userid = req.body.userid;
  var orgname = req.body.orgName;
  let isRegistered = await caActions.checkExists(userid, orgname);

  if (isRegistered) {
    const token = jwt.sign({ orgname, userid}, jwtKey, {
      algorithm: "HS256",
      expiresIn: jwtExpirySeconds,
    })
    console.log("token:", token);
    return res.status(200).json({response: token});
  } else {
    return res.status(403).json({ error: 'The user does not exist in the wallet' });
  }
});


app.use(function(req, res, next) {
  if (!req.headers.authorization) {
    return res.status(403).json({ error: 'No credentials sent!' });
  }
  next();
});

app.post('/ledger/invoke', async function (req, res) {

  const tokenR =  req.headers.authorization.split(' ')[1];
  console.log("tokenR:", tokenR);
  var payload
	try {
		// Parse the JWT string and store the result in `payload`.
		payload = jwt.verify(tokenR, jwtKey)
	} catch (e) {
		if (e instanceof jwt.JsonWebTokenError) {
			// if the error thrown is because the JWT is unauthorized, return a 401 error
			return res.status(401).end()
		}
		// otherwise, return a bad request error
		return res.status(400).end()
	}
  var identifier = Nanoid.nanoid();
  var orgname = payload.orgname;
  var userId = payload.userid;
  var idOrgS = req.body.idOrgS;
  var nameOrgS = req.body.nameOrgS;
  var idOrgD = req.body.idOrgD;
  var nameOrgD = req.body.nameOrgD;
  var validityDate = req.body.validityDate;
  var idPatient = req.body.idPatient;
  var purpose = req.body.purpose;

  let date_ob = new Date();
  let date = ("0" + date_ob.getDate()).slice(-2);
  let month = ("0" + (date_ob.getMonth() + 1)).slice(-2);
  let year = date_ob.getFullYear();
  let hours = date_ob.getHours();
  let minutes = date_ob.getMinutes();
  let seconds = date_ob.getSeconds();

  var recorded = year + "-" + month + "-" + date + "/" + hours + ":" + minutes + ":" + seconds;

    // Evaluate the specified transaction.
    const result = await ledgerActions.invoke(orgname, userId, identifier, idOrgS, 
      nameOrgS, idOrgD, nameOrgD, validityDate, idPatient, purpose, recorded);
    console.log(`Transaction has been evaluated, result is: ${result.toString()}`);

    if (result.split(' ')[0] == 'Error.') {
      console.error(`Failed to evaluate transaction: ${result}`);
      res.status(500).json({error: result});
      process.exit(1);
    }

    else {
      res.status(200).json({response: result.toString()});
    }
});


app.get('/ledger/query', async function (req, res) {
  const tokenR = req.headers.authorization.split(' ')[1];
  var payload
	try {
		// Parse the JWT string and store the result in `payload`.
		payload = jwt.verify(tokenR, jwtKey)
    console.log("payload:", payload);
	} catch (e) {
		if (e instanceof jwt.JsonWebTokenError) {
			// if the error thrown is because the JWT is unauthorized, return a 401 error
			return res.status(401).end()
		}
		// otherwise, return a bad request error
		return res.status(400).end()
	}
  let orgname = payload.orgname;
  let userId = payload.userid;
  let fun = req.query.fun;
  let arg = req.query.arg;

  const result = await ledgerActions.query(orgname, userId, fun, arg);
  console.log(`Transaction has been evaluated, result is: ${result.toString()}`);

  if (result.split(' ')[0] == 'Error.') {
    console.error(`Failed to evaluate transaction: ${result}`);
    res.status(500).json({error: result});
    process.exit(1);
  }

  else {
    res.status(200).json({assets: result.toString()});
  }
});
