'use strict';
var log4js = require('log4js');
log4js.configure({
	appenders: {
		out: { type: 'stdout' },
	},
	categories: {
		default: { appenders: ['out'], level: 'info' },
	}
});
var logger = log4js.getLogger('BCIOTAPI');
const WebSocketServer = require('ws');
var express = require('express');
var bodyParser = require('body-parser');
var http = require('http');
var util = require('util');
var app = express();
var cors = require('cors');
var hfc = require('fabric-client');
const uuidv4 = require('uuid/v4');

var connection = require('./connection.js');
var query = require('./query.js');
var invoke = require('./invoke.js');
var blockListener = require('./blocklistener.js');
var channelInfo = require('./channelInfo.js');

hfc.addConfigFile('config.json');
var host = 'localhost';
var port = 3000;
var username = "";
var orgName = "";
var channelName = hfc.getConfigSetting('channelName');
var chaincodeName = hfc.getConfigSetting('chaincodeName');
var peers = hfc.getConfigSetting('peers');
var organizationIdentity = hfc.getConfigSetting('organizationIdentity');

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// SET CONFIGURATIONS ///////////////////////////
///////////////////////////////////////////////////////////////////////////////
app.options('*', cors());
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
	extended: false
}));
app.use(function (req, res, next) {
	logger.info(' ##### New request for URL %s', req.originalUrl);
	return next();
});

//wrapper to handle errors thrown by async functions. We can catch all
//errors thrown by async functions in a single place, here in this function,
//rather than having a try-catch in every function below. The 'next' statement
//used here will invoke the error handler function - see the end of this script
const awaitHandler = (fn) => {
	return async (req, res, next) => {
		try {
			await fn(req, res, next)
		}
		catch (err) {
			next(err)
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// START SERVER /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
var server = http.createServer(app).listen(port, function () { });
logger.info('****************** SERVER STARTED ************************');
logger.info('***************  Listening on: http://%s:%s  ******************', host, port);
server.timeout = 240000;

function getErrorMessage(field) {
	var response = {
		success: false,
		message: field + ' field is missing or Invalid in the request'
	};
	return response;
}

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// START WEBSOCKET SERVER ///////////////////////
///////////////////////////////////////////////////////////////////////////////
const wss = new WebSocketServer.Server({ server });
wss.on('connection', function connection(ws) {
	logger.info('****************** WEBSOCKET SERVER - received connection ************************');
	ws.on('message', function incoming(message) {
		console.log('##### Websocket Server received message: %s', message);
	});

	ws.send('something');
});

///////////////////////////////////////////////////////////////////////////////
///////////////////////// REST ENDPOINTS START HERE ///////////////////////////
///////////////////////////////////////////////////////////////////////////////
// Health check - can be called by load balancer to check health of REST API
app.get('/health', awaitHandler(async (req, res) => {
	res.sendStatus(200);
}));

// Register and enroll user. A user must be registered and enrolled before any queries 
// or transactions can be invoked
app.post('/users', awaitHandler(async (req, res) => {
	logger.info('================ POST on Users');
	username = req.body.username;
	orgName = req.body.orgName;
	logger.info('##### End point : /users');
	logger.info('##### POST on Users- username : ' + username);
	logger.info('##### POST on Users - userorg  : ' + orgName);
	let response = await connection.getRegisteredUser(username, orgName, true);
	logger.info('##### POST on Users - returned from registering the username %s for organization %s', username, orgName);
	logger.info('##### POST on Users - getRegisteredUser response secret %s', response.secret);
	logger.info('##### POST on Users - getRegisteredUser response secret %s', response.message);
	if (response && typeof response !== 'string') {
		logger.info('##### POST on Users - Successfully registered the username %s for organization %s', username, orgName);
		logger.info('##### POST on Users - getRegisteredUser response %s', response);
		// Now that we have a username & org, we can start the block listener
		await blockListener.startBlockListener(channelName, username, orgName, wss);
		res.json(response);
	} else {
		logger.error('##### POST on Users - Failed to register the username %s for organization %s with::%s', username, orgName, response);
		res.json({ success: false, message: response });
	}
}));

app.delete('/users', awaitHandler(async (req, res) => {
	logger.info('================ DELETE on Users');
	username = req.body.username;
	orgName = req.body.orgName;
	logger.info('##### End point : /users');
	logger.info('##### DELETE on Users- username : ' + username);
	logger.info('##### DELETE on Users - userorg  : ' + orgName);
	let response = await connection.revokeRegisteredUser(username, orgName);
	logger.info('##### DELETE on Users - returned from registering the username %s for organization %s', username, orgName);
	res.json({ success: true });
}));

app.get('/channel/height', awaitHandler(async (req, res) => {
	logger.info('================ GET on ChannelInfo');
	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await channelInfo.queryChannelInfo(peers, channelName, username, orgName);
	res.send(message);
}));

app.get('/channel/block', awaitHandler(async (req, res) => {
	let args = parseInt(req.query.BlockNumber)
	logger.info('================ GET on ChannelInfo');
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await channelInfo.queryBlock(args, peers, channelName, username, orgName);
	res.send(message);
}));

app.get('/channel/block/tx_id', awaitHandler(async (req, res) => {
	let args = toString(req.query.TxID)
	logger.info('================ GET on ChannelInfo');
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await channelInfo.queryBlockByTxID(args, peers, channelName, username, orgName);
	res.send(message);
}));

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// CUSTOM APIs //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

//Purchase Order
app.post('/purchase-order', awaitHandler(async (req, res) => {
	logger.info('================ POST on Purchase Order');
	let args = JSON.stringify(req.body)
	let fcn = "createPurchaseOrder";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.get('/purchase-order', awaitHandler(async (req, res) => {
	logger.info('================ GET on Purchase Order');
	let args = JSON.stringify({
		"PurchaseOrderID": req.query.PurchaseOrderID,
		"Owner": req.query.Owner
	});
	let fcn = "getPurchaseOrder";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.delete('/purchase-order', awaitHandler(async (req, res) => {
	logger.info('================ DELETE on Purchase Order');
	let args = JSON.stringify({
		"PurchaseOrderID": req.query.PurchaseOrderID,
		"Owner": req.query.Owner
	});
	let fcn = "deletePurchaseOrder";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Production Order
app.post('/report/goods-receipt/production-order', awaitHandler(async (req, res) => {
	logger.info('================ POST on Production Order Goods Receipt');
	let args = JSON.stringify(req.body)
	let fcn = "reportProductionOrderGR";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.get('/production-order', awaitHandler(async (req, res) => {
	logger.info('================ GET on Production Order');
	let args = JSON.stringify({
		"ProductionOrderID": req.query.ProductionOrderID,
		"Owner": req.query.Owner
	});
	let fcn = "getProductionOrder";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.delete('/production-order', awaitHandler(async (req, res) => {
	logger.info('================ DELETE on Production Order');
	let args = JSON.stringify({
		"ProductionOrderID": req.query.ProductionOrderID,
		"Owner": req.query.Owner
	});
	let fcn = "deleteProductionOrder";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Sales Order
app.post('/sales-order', awaitHandler(async (req, res) => {
	logger.info('================ POST on Sales Order');
	let args = JSON.stringify(req.body)
	let fcn = "createSalesOrder";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.get('/sales-order', awaitHandler(async (req, res) => {
	logger.info('================ GET on Sales Order');
	let args = JSON.stringify({
		"SalesOrderID": req.query.SalesOrderID,
		"Owner": req.query.Owner
	});
	let fcn = "getSalesOrder";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.delete('/sales-order', awaitHandler(async (req, res) => {
	logger.info('================ DELETE on Sales Order');
	let args = JSON.stringify({
		"SalesOrderID": req.query.SalesOrderID,
		"Owner": req.query.Owner
	});
	let fcn = "deleteSalesOrder";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Delivery
app.post('/delivery', awaitHandler(async (req, res) => {
	logger.info('================ POST on Delivery');
	let args = JSON.stringify(req.body)
	let fcn = "createDelivery";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.get('/delivery', awaitHandler(async (req, res) => {
	logger.info('================ GET on Delivery');
	let args = JSON.stringify({
		"SalesOrderID": req.query.SalesOrderID,
		"DeliveryNumber": req.query.DeliveryNumber,
		"Owner": req.query.Owner
	});
	let fcn = "getDelivery";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.delete('/delivery', awaitHandler(async (req, res) => {
	logger.info('================ DELETE on Production Order');
	let args = JSON.stringify({
		"SalesOrderID": req.query.SalesOrderID,
		"DeliveryNumber": req.query.DeliveryNumber,
		"Owner": req.query.Owner
	});
	let fcn = "deleteDelivery";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Shipment
app.post('/shipment', awaitHandler(async (req, res) => {
	logger.info('================ POST on Shipment');
	let args = JSON.stringify(req.body)
	let fcn = "createShipment";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.get('/shipment', awaitHandler(async (req, res) => {
	logger.info('================ GET on Shipment');
	let args = req.query.ShipmentID;
	let fcn = "getShipment";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.delete('/shipment', awaitHandler(async (req, res) => {
	logger.info('================ DELETE on Shipment');
	let args = req.query.ShipmentID;
	let fcn = "deleteShipment";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Shipment Sensor Readings
app.post('/report/shipment/sensor-reading', awaitHandler(async (req, res) => {
	logger.info('================ POST on Shipment Sensor Reading');
	let args = JSON.stringify(req.body);
	let fcn = "reportSensorReading";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Shipment Contamination
app.post('/report/shipment/contamination', awaitHandler(async (req, res) => {
	logger.info('================ POST on Shipment Contamination');
	let args = req.query.ShipmentID;
	let fcn = "reportShipmentContamination";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Goods Receipt Purchase Order 
app.post('/report/goods-receipt/purchase-order', awaitHandler(async (req, res) => {
	logger.info('================ POST on Purchase Order Goods Receipt');
	let args = JSON.stringify(req.body);
	let fcn = "reportPurchaseOrderGR";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Batch
app.get('/batch', awaitHandler(async (req, res) => {
	logger.info('================ GET on Batch');
	let args = JSON.stringify({
		"MaterialID": req.query.MaterialID,
		"BatchNumber": req.query.BatchNumber,
		"Owner": req.query.Owner
	});
	let fcn = "getBatch";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.delete('/batch', awaitHandler(async (req, res) => {
	logger.info('================ DELETE on Batch');
	let args = JSON.stringify({
		"MaterialID": req.query.MaterialID,
		"BatchNumber": req.query.BatchNumber,
		"Owner": req.query.Owner
	});
	let fcn = "deleteBatch";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Material
app.get('/material', awaitHandler(async (req, res) => {
	logger.info('================ GET on Material');
	let args = req.query.MaterialID;
	let fcn = "getMaterial";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

app.delete('/material', awaitHandler(async (req, res) => {
	logger.info('================ DELETE on Material');
	let args = req.query.MaterialID;
	let fcn = "deleteMaterial";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await invoke.invokeChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Query Ledger
app.post('/ledger/query', awaitHandler(async (req, res) => {
	logger.info('================ Query on Ledger Data');
	let args = JSON.stringify(req.body);
	let fcn = "customQueries";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

//Asset History
app.get('/ledger/history', awaitHandler(async (req, res) => {
	logger.info('================ Query on Ledger History');
	let args = req.query.AssetID;
	let fcn = "getHistory";

	logger.info('##### Request INFO - username : ' + username);
	logger.info('##### Request INFO - userOrg : ' + orgName);
	logger.info('##### Request INFO - channelName : ' + channelName);
	logger.info('##### Request INFO - chaincodeName : ' + chaincodeName);
	logger.info('##### Request INFO - fcn : ' + fcn);
	logger.info('##### Request INFO - args : ' + args);
	logger.info('##### Request INFO - peers : ' + peers);

	let message = await query.queryChaincode(peers, channelName, chaincodeName, organizationIdentity, args, fcn, username, orgName);
	res.send(message);
}));

/************************************************************************************
 * Error handler
 ************************************************************************************/

app.use(function (error, req, res, next) {
	res.status(500).json({ error: error.toString() });
});
