##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# Requires
elasticsearch = require 'elasticsearch'
q = require 'q'
chalk = require 'chalk'
mongo = require 'mongodb'
mongodbClient = mongo.MongoClient
yargs = require 'yargs'

# Command line arguments
argv = yargs
    .usage('Usage: $0 --db \"mongodb://localhost:27017/metrics\" --collection github --elasticHost localhost --elasticIndex github')
    .demand(['db', 'collection', 'elasticHost', 'elasticIndex'])
    .argv;

cli_arg_mongodb_url = argv.db
cli_arg_db_collection = argv.collection
cli_arg_es_host = argv.elasticHost
cli_arg_es_index = argv.elasticIndex

# Elastic Stuff
type = 'projects'
elasticClient = new elasticsearch.Client {
	host: cli_arg_es_host+':9200'
	# log: 'trace'
}

# Open connection to Database
collection = mongodbClient.connect cli_arg_mongodb_url, (err, db) ->
	console.log ''
	console.log 'Connecting to mongodb at ', chalk.yellow cli_arg_mongodb_url
	console.log "  unable to access database: #{err}" if err
	collection = db.collection cli_arg_db_collection
	console.log '  using collection ', chalk.yellow cli_arg_db_collection

	if !collection
		console.log
		console.log chalk.red 'Fatal error, unable to write to database'
		console.log
		process.exit
	else
		gatherMetrics()


gatherMetrics = () =>

	console.log "request to pull metrics"

	query = {
		"_source": "languages.*",
		"query": {
			"match_all": {}
		},
		"aggs" : {
	        "total_java_sloc" : { "sum" : { "field" : "languages.Java" } },
	        "total_c_sloc" : { "sum" : { "field" : "languages.C" } },
	        "total_cpp_sloc" : { "sum" : { "field" : "languages.C++" } },
	        "avg_java_sloc" : { "avg" : { "field" : "languages.Java" } },
	        "avg_c_sloc" : { "avg" : { "field" : "languages.C" } },
	        "avg_cpp_sloc" : { "avg" : { "field" : "languages.C++" } },
	        "count_java_projects" : { "value_count" : { "field" : "languages.Java" } },
	        "count_c_projects" : { "value_count" : { "field" : "languages.C" } },
	        "count_cpp_projects" : { "value_count" : { "field" : "languages.C++" } }
	    }
	}

	full_query = {
		index: cli_arg_es_index,
		type: "projects",
		"search_type": "count",
		body: query
	}

	elasticClient.search full_query
		. then (body) =>
			
			#console.log chalk.cyan JSON.stringify body, null, 4

			datestring = new Date().toISOString().replace(/T.*/, '')
			data = [
				"date": datestring,
				"total_num_projects": body.hits.total,
				"total_java_sloc": body.aggregations.total_java_sloc.value,
				"total_c_sloc": body.aggregations.total_c_sloc.value,
				"total_cpp_sloc": body.aggregations.total_cpp_sloc.value,
				"avg_java_sloc": Math.round(body.aggregations.avg_java_sloc.value),
				"avg_c_sloc": Math.round(body.aggregations.avg_c_sloc.value),
				"avg_cpp_sloc": Math.round(body.aggregations.avg_cpp_sloc.value),
				"count_java_projects": body.aggregations.count_java_projects.value,
				"count_c_projects": body.aggregations.count_c_projects.value,
				"count_cpp_projects": body.aggregations.count_cpp_projects.value
			]
			
			gatherHistogram data


		, (err) ->
			console.log chalk.red err.message


# So we want to know small medium and large projects in terms of SLOC
# we will define tiny < 1000
# small as < 10,000,
# medium as < 100,000
# and large as > 100,000
calculateBuckets = (buckets, callback) =>
	tiny = 0
	small = 0
	medium = 0
	large = 0
	for key in buckets
		if key.key < 1000
			tiny += key.doc_count
		else if key.key < 10000
			small += key.doc_count
		else if key.key < 100000
			medium += key.doc_count
		else
			large += key.doc_count

	callback tiny, small, medium, large


gatherHistogram = (data) =>

	console.log "request to pull histogram"

	query = {
		"query": {
			"match_all": {}
		},
		"partial_fields": {
			"partial1" : {
				"include" : "languages.*"
			}
		},
		"aggs" : {
			"java" : {
				"histogram" : {
					"field" : "languages.Java",
					"interval": 1000
				}
			},
			"c" : {
				"histogram" : {
					"field" : "languages.C",
					"interval": 1000
				}
			},
			"cpp" : {
				"histogram" : {
					"field" : "languages.C++",
					"interval": 1000
				}
			}
		}
	}

	full_query = {
		index: cli_arg_es_index,
		body: query
	}

	elasticClient.search full_query
		. then (body) =>
			#console.log chalk.cyan JSON.stringify body.aggregations, null, 2

			calculateBuckets body.aggregations.cpp.buckets, (tiny, small, medium, large) =>
				#console.log chalk.cyan "cpp: " + tiny + " " + small + " " + medium + " " + large
				data[0]["cpp_sloc_hist"] = [tiny, small, medium, large]

				calculateBuckets body.aggregations.c.buckets, (tiny, small, medium, large) =>
					#console.log chalk.cyan "c: " + tiny + " " + small + " " + medium + " " + large
					data[0]["c_sloc_hist"] = [tiny, small, medium, large]

					calculateBuckets body.aggregations.java.buckets, (tiny, small, medium, large) =>
						#console.log chalk.cyan "java: " + tiny + " " + small + " " + medium + " " + large
						data[0]["java_sloc_hist"] = [tiny, small, medium, large]


						#console.log chalk.yellow JSON.stringify data, null, 4

						collection.insert data, {w:1}, (err, docs) ->
						    console.log "Unable to save record: #{err}" if err
							process.exit()

		, (err) ->
			console.log chalk.red err.message
