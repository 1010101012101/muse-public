##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
chalk = require 'chalk'
https = require 'https'
url = require 'url'
mongo = require 'mongodb'
sleep = require 'sleep'
client = mongo.MongoClient
yargs = require 'yargs'

argv = yargs
    .usage('Usage: $0 --token 377sdgsr32r3afpafsp --mongoDb \"mongoDb://localhost:27017/github\" --mongoCollection github_1 --since')
    .demand(['token','mongoDb', 'mongoCollection'])
    .argv;

# Need to define these better
token = argv.token
db_url = argv.mongoDb
db_collection = argv.mongoCollection

check_point = 0
if (argv.since)
	check_point = argv.since

# Open connection to Database
collection = client.connect db_url, (err, db) ->
	console.log ''
	console.log 'Connecting to mongodb at ', chalk.yellow db_url
	if err 
		console.log "  unable to access database: #{err}"
		console.log "  check --mongo host"
		throw err	
	collection = db.collection db_collection
	console.log '  using collection ', chalk.yellow db_collection

	if !collection
		console.log
		console.log chalk.red 'Fatal error, unable to write to database'
		console.log
		process.exit
	else
		tryRateLimit collection

# `getRateLimitInfo` calls the github API to retrieve the current rate limit parameters
getRateLimitInfo = (callback) ->
	options = 
		hostname: 'api.github.com'
		port: 443
		path: 'https://api.github.com:443/rate_limit?' + 'access_token=' + token
		method: 'GET'
		headers : {
	    	'User-Agent' : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1521.3 Safari/537.36'
	    }

	# console.log '  path: ' + options.path
	console.log ''
	console.log 'Requesting rate limit information from github.com'
	request = https.get options, (response) ->

		console.log "  statusCode: ", chalk.yellow response.statusCode
		#link = response.headers.link

		data = []

		response.on 'data', (chunk) -> 
			data.push(chunk)

		response.on 'end', (page) ->
			result = JSON.parse data.join ''
			callback result.rate

	request.on 'error', (error) ->
		console.log("Got error: " + error.message)

	request.end

# Make our first call to the API to return rate information
tryRateLimit = (collection) ->
	getRateLimitInfo (rate_limit) ->
		console.log chalk.magenta '    limit ' + rate_limit.limit + ', remaining: ' + rate_limit.remaining + ', reset: ' + rate_limit.reset
		if !rate_limit
			console.log
			console.log chalk.red 'Fatal: unable to get rate information'
			console.log
			process.exit
		else
			request_number = rate_limit.limit - rate_limit.remaining + 1
			# Start the request for projects, this will recurse
			makeGetRequest '&since=' + check_point, collection, request_number, rate_limit
	
#
# `printProjectIds`
#
printProjectIds = (projects, collection, request_number, rate_limit) ->
	
	if projects == null
		console.log chalk.red 'Fatal: No projects found, exiting'
		process.exit
	else
		# Print
		console.log '  adding projects ', chalk.cyan projects[0].id, chalk.reset ' to ', chalk.cyan projects[projects.length-1].id, chalk.reset ' to database'

		# Store in mongodb
		for project in projects
			collection.insert project, {w:1}, (err, docs) ->
		        console.log "Unable to save record: #{err}" if err
		console.log '  last project url is ', chalk.blue projects[projects.length-1].html_url

		# Next!
		request_number++
		if (request_number >= rate_limit.limit)
			updateRateLimitInfo '&since=' + projects[projects.length-1].id, collection
		else
			makeGetRequest '&since=' + projects[projects.length-1].id, collection, request_number, rate_limit
	
#
#
#
updateRateLimitInfo = (since, collection) ->
	console.log ''
	console.log chalk.red 'Reached the maximum number of requests per hour...'
	console.log '  updating rate information...'
	getRateLimitInfo (rate_limit) ->
		console.log chalk.magenta '    limit ' + rate_limit.limit + ', remaining: ' + rate_limit.remaining + ', reset: ' + rate_limit.reset
		if rate_limit.remaining == 0
			d = new Date()
			delta = rate_limit.reset - (Date.parse(d) / 1000)
			console.log '  sleeping for ', chalk.red delta, chalk.reset ' seconds'
			sleep(delta)
			rate_limit = getRateLimitInfo (rate_limit) ->
				request_number = rate_limit.limit - rate_limit.remaining + 1
				makeGetRequest since, collection, request_number, rate_limit
		else
			request_number = rate_limit.limit - rate_limit.remaining + 1
			makeGetRequest since, collection, request_number, rate_limit


#
# `makeGetRequest`
#
makeGetRequest = (since, collection, request_number, rate_limit) ->


	options = 
		hostname: 'api.github.com'
		port: 443
		path: 'https://api.github.com:443/repositories?' + 'access_token=' + token + since
		method: 'GET'
		headers : {
	    	'User-Agent' : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1521.3 Safari/537.36'
	    }

	# console.log '  path: ' + options.path
	console.log ''
	console.log "Request #", chalk.cyan request_number, chalk.reset " to github.com"
	request = https.get options, (response) ->

		console.log "  statusCode: ", chalk.yellow response.statusCode
		#link = response.headers.link

		data = []

		response.on 'data', (chunk) -> 
			data.push(chunk)

		response.on 'end', (page) ->
			result = JSON.parse data.join ''

			printProjectIds result, collection, request_number, rate_limit


	request.on 'error', (error) ->
		console.log("Got error: " + error.message)

	request.end



