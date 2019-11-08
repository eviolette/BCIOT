var util = require('util');
var helper = require('./connection.js');
var logger = helper.getLogger('ChannelInfo');

var queryChannelInfo = async function (peers, channelName, username, orgName) {
    try {
        // setup the client for this org
        var client = await helper.getClientForOrg(orgName, username);
        logger.info('============ START channelInfo - Successfully got the fabric client for the organization "%s"', orgName);
        var channel = client.getChannel(channelName);
        if (!channel) {
            let message = util.format('##### channelInfo - Channel %s was not defined in the connection profile', channelName);
            logger.error(message);
            throw new Error(message);
        }
        logger.info('##### channelInfo - Query Info request to Fabric');
        let result = await channel.queryInfo(peers[0]);
        if (result) {
            logger.info(result)
            return result
        } else {
            logger.error('Response Payload is Null!');
            return 'Response Payload is Null';
        }
    }
    catch (error) {
        logger.error('##### channelInfo - Failed to query due to error: ' + error.stack ? error.stack : error);
        return error.toString();
    }
};

var queryBlock = async function (blockNumber, peers, channelName, username, orgName) {
    try {
        // setup the client for this org
        var client = await helper.getClientForOrg(orgName, username);
        logger.info('============ START channelInfo - Successfully got the fabric client for the organization "%s"', orgName);
        var channel = client.getChannel(channelName);
        if (!channel) {
            let message = util.format('##### channelInfo - Channel %s was not defined in the connection profile', channelName);
            logger.error(message);
            throw new Error(message);
        }
        logger.info('##### channelInfo - Query Block by Block Number');
        let result = await channel.queryBlock(blockNumber, peers[0]);
        if (result) {
            logger.info(result)
            return result
        } else {
            logger.error('Response Payload is Null!');
            return 'Response Payload is Null';
        }
    }
    catch (error) {
        logger.error('##### channelInfo - Failed to query due to error: ' + error.stack ? error.stack : error);
        return error.toString();
    }
};

var queryBlockByTxID = async function (tx_id, peers, channelName, username, orgName) {
    try {
        // setup the client for this org
        var client = await helper.getClientForOrg(orgName, username);
        logger.info('============ START channelInfo - Successfully got the fabric client for the organization "%s"', orgName);
        var channel = client.getChannel(channelName);
        if (!channel) {
            let message = util.format('##### channelInfo - Channel %s was not defined in the connection profile', channelName);
            logger.error(message);
            throw new Error(message);
        }
        logger.info('##### channelInfo - Query Block by Transaction ID');
        let result = await channel.queryBlockByTxID(tx_id, peers[0]);
        if (result) {
            logger.info(result)
            return result
        } else {
            logger.error('Response Payload is Null!');
            return 'Response Payload is Null';
        }
    }
    catch (error) {
        logger.error('##### channelInfo - Failed to query due to error: ' + error.stack ? error.stack : error);
        return error.toString();
    }
};


exports.queryChannelInfo = queryChannelInfo;
exports.queryBlock = queryBlock;
exports.queryBlockByTxID = queryBlockByTxID;