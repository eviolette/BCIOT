var util = require('util');
var helper = require('./connection.js');
var logger = helper.getLogger('ChannelInfo');

var queryChannelInfo = async function(peers, channelName, username, orgName) {
	try {
		// setup the client for this org
		var client = await helper.getClientForOrg(orgName, username);
		logger.info('============ START channelInfo - Successfully got the fabric client for the organization "%s"', orgName);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = util.format('##### channelInfo - Channel %s was not defined in the connection profile', channelName);
			logger.error(message);
			throw new Error(message);
        }
		logger.info('##### channelInfo - Query Info request to Fabric');
        let result = await channel.queryInfo(peers[0]);
        let response = result.toString('utf8');
        logger.info('##### channelInfo - response : %s', response);
        let ret = [];
        let json = JSON.parse(response);
        ret.push(json);
        return ret;
	} 
	catch(error) {
		logger.error('##### channelInfo - Failed to query due to error: ' + error.stack ? error.stack : error);
		return error.toString();
	}
};

exports.queryChannelInfo = queryChannelInfo;