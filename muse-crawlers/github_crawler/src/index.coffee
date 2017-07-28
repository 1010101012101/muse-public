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
sleep = require 'sleep'
uuid = require 'uuid'
yargs = require 'yargs'
fs = require 'fs'
util = require 'util'
octonode = require 'octonode'
async = require 'async'
GitCrawler = require './GitCrawler'

NanoTimer = require 'nanotimer'
timer = new NanoTimer()

exports.Scope = class Scope

require 'shelljs/global'

mongodb = require 'mongodb'
mongo = mongodb.MongoClient

redisdb = require 'redis'

# Command line arguments
argv = yargs
    .usage('Usage: $0 --token 377sdgsr32r3afpafsp ' +
    	'--mongoDb \"mongodb://localhost:27017/github\" ' +
    	'--mongoCollection github_1 ' +
    	'--redisHost \"localhost\" ' +
    	'--redisDb 3 ' +
    	'--out /datastore')
    .demand(['token','mongoDb', 'mongoCollection', 'out'])
    .argv;

token = argv.token
db_url = argv.mongoDb
db_collection = argv.mongoCollection
download_path = argv.out
redis_database = argv.redisDb
redis_host = argv.redisHost

process.title = "github-crawler";

# Check for required software
required_sw = ["git"]
for app in required_sw
		if not which app
			console.log chalk.red 'Fatal error: requires ' + app

# Display download location
console.log ''
console.log 'Projects will be downloaded to:'
console.log '  ', chalk.yellow download_path

mongo.connect db_url, (err, db) =>
	console.log ''
	console.log 'Connecting to mongodb at ', chalk.yellow db_url
	console.log "  unable to access database: #{err}" if err
	collection = db.collection db_collection
	console.log '  using collection ', chalk.yellow db_collection

	# Next step
	doRedisConnect collection


getPath = (download_path, uuid) =>
	result = uuid.split("", 8)
	res_path = ''
	for res in  result 
		res_path += res + '/'

	return download_path + '/' + res_path + uuid

# Open redis connection
doRedisConnect = (mongo_collection) =>

	console.log ''
	console.log 'Connecting to redis server at ', chalk.yellow redis_host
	redis = redisdb.createClient 6379, redis_host, {}

	redis.on 'connect', (err, res) =>

		redis.select redis_database, () =>

			console.log '  using database ' , chalk.yellow redis_database
			#redis.set("string key", "string val", redis.print);

			# Open Github API
			github = octonode.client token
			github.limit (err, left, max) =>

				console.log ''
				console.log 'Checking ratelimit for Github API'
				console.log chalk.magenta '    limit ' + max + ', remaining: ' + left

				cm = new CrawlerManager mongo_collection, redis, github
				cm.start()

	redis.on 'error', (err) =>
		    console.log chalk.red "error event - " + redis_host + ":6379 - " + err


# This application needs to get some project ids from the mongodb instance
# perhaps register that fact in redis
# Need to make sure that Unique IDs are maintained here.
# That is all dealing with data movement and being able to run multiple crawlers
class CrawlerManager

	_downloaded: 0

	constructor: (@mongo_collection, @redis, @github) ->

	get_count: ->
    	@_downloaded

	start: () ->

		console.log ''
		process.stdout.write chalk.bold 'Fetching greatest github ID crawled...'

		@redis.get 'greatest', (err, greatest) =>
			greatest = 0 if err
			console.log chalk.bold chalk.cyan greatest
			@mongo_collection.findOne { id: {$gt: parseInt(greatest)}}, (err, project) =>
				console.log chalk.red "No projects found" if err
				@crawlProject project

	# The actual crawling...
	crawlProject: (levelzero) ->

		# Check for existing uuid
		@redis.get "id-to-uuid:github:"+levelzero.id.toString(), (err, reply) =>
			console.log chalk.red err if err

			console.log ''
			console.log '  github id ', chalk.blue levelzero.id

			if reply
				console.log chalk.yellow '  already exists, overwrite will occur '
				id = reply
			else
				console.log '  generating a new uuid'
				id = uuid.v4()

			console.log '  is uniquely identified as ', chalk.magenta id
			console.log ''

			# Update Mapping
			@redis.set "id-to-uuid:github:"+levelzero.id.toString(), id.toString(), (err, reply) =>
				console.log chalk.red err if err

				@redis.set "uuid-to-id:github:"+id.toString(), levelzero.id.toString(), (err, reply) =>
					console.log chalk.red err if err

					project_path = getPath('/data/corpus_0to7',id);
					fs.exists project_path,(exists) => 
						if ! exists
							project_path = getPath('/data/corpus_8tof',id);
							fs.exists project_path,(exists2) => 
								if ! exists2
									# Download project
									gc = GitCrawler @github, download_path
									gc.download levelzero.full_name, id, () =>
	
										# Mark Done and goto next
										@redis.set 'greatest', levelzero.id.toString(), (err, reply) =>
											console.log chalk.red err if err

											@_downloaded++
											@redis.set 'downloaded', @_downloaded.toString(), (err, reply) =>
												console.log err, reply if err
												@start()
								else
									console.log chalk.yellow '  already exists in main corpus at: /data/corpus_8tof/'
									@redis.set 'greatest', levelzero.id.toString(), (err, reply) =>
										console.log chalk.red err if err
										@start()
						else 
							console.log chalk.yellow '  already exists in main corpus at: /data/corpus_0to7/'
							@redis.set 'greatest', levelzero.id.toString(), (err, reply) =>
								console.log chalk.red err if err
								@start()


