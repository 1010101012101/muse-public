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
    	'--redisDb 8 ' +
    	'--out /datastore' +
        '--query github_query')
    .demand(['token','mongoDb', 'mongoCollection', 'out', 'query'])
    .argv;

token = argv.token
db_url = argv.mongoDb
db_collection = argv.mongoCollection
download_path = argv.out
redis_database = argv.redisDb
redis_host = argv.redisHost
san_path1 = '/data/corpus_0to7'
san_path2 = '/data/corpus_8tof'
query = argv.query
github = octonode.client token

process.title = "github-search-crawler";

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
			start mongo_collection, redis 

	redis.on 'error', (err) =>
		 console.log chalk.red "error event - " + redis_host + ":6379 - " + err

start = (mongo_collection, redis ) =>
	console.log ''
	console.log 'Starting GitHub Search-Query Crawl...'
	console.log ''
	number = 1
	pages = [1,2,3,4,5,6,7,8,9,10]
	ghsearch = github.search()

	async.eachSeries pages, (page, callback1) =>   
		console.log ''
		ghsearch.repos {q: query, page: page, per_page: 100}, (err, results) =>
			if err
				console.log err
				return callback1()
			else
				console.log 'Github Search returned: ' + results.total_count
				console.log 'Page: ' + page
				console.log 'Total items on page: ' + results.items.length
				async.eachSeries results.items, (repo, callback) => 
					console.log '---------------------------------------'
					console.log 'Working on #' + number++ + ' of ' + results.total_count
					console.log '  projectID: ' + repo.id + ' name: ' + repo.full_name
					console.log ''
				
					
					mongo_collection.findOne { id: {$gt: parseInt(repo.id)}}, (err, project) =>
						if err 
							console.log chalk.red "  Mongo: No project found"
							return callback()
						else
							if project
								console.log '  Mongo: already has projectID'
								redisCheck redis, repo, callback 
							else
								console.log '  Mongo: not found; inserting now'
								mongo_collection.insert repo, {w: 1}, (err, docs) =>
								if err
									console.log err
									return callback()
								else
									redisCheck redis, repo, callback 
									
redisCheck = (redis, project, callback) =>
	console.log ''
	console.log '  Redis: checking github id: ' + chalk.blue(project.id)
	redis.get 'id-to-uuid:github:' + project.id.toString(), (err, reply) =>
		id = ''
		if err
			console.log chalk.red(err)
			return callback()
		else
			if reply
				console.log chalk.yellow('  already exists; overwriting...')
				id = reply
			else
				console.log '  generating a new uuid'
				id = uuid.v4()
				redis.set 'id-to-uuid:github:' + project.id.toString(), id.toString(), (err, reply) =>
					if err
						console.log chalk.red err
						return callback()
					else
						redis.set 'id-to-uuid:github:' + project.id.toString(), id.toString(), (err, reply) =>
							if err
								console.log chalk.red err
								return callback()
						
			console.log '  is uniquely identified as ', chalk.magenta(id)
			console.log ''
			project_path = getPath(san_path1,id)
			fs.exists project_path, (exists) =>
				if exists
					console.log '  already exists in corpus at: ' + san_path1
					return callback()
				else
					project_path = getPath(san_path2,id)
					fs.exists project_path, (exists) =>
						if exists
							console.log '  already exists in corpus at ' + san_path2
							return callback()
						else
							project_path = getPath(download_path,id)
							fs.exists project_path, (exists) =>
								if exists
									console.log '  already downloaded at: ' + download_path
									return callback()
								else
									gc = GitCrawler(github, download_path)
									github.limit (err, left, max) =>
										console.log "  Rate limiting remaining: " + left + " of " + max
										console.log ""
										if left < 100
											console.log 'sleeping 10 minutes'
											setTimeout(900000) =>
												gc.download project.full_name, id, () =>
													return callback()
										else
											gc.download project.full_name, id, () =>
												return callback()
