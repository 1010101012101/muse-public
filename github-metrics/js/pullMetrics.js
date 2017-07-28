/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
(function() {
  var argv, calculateBuckets, chalk, cli_arg_db_collection, cli_arg_es_host, cli_arg_es_index, cli_arg_mongodb_url, collection, elasticClient, elasticsearch, gatherHistogram, gatherMetrics, mongo, mongodbClient, q, type, yargs;

  elasticsearch = require('elasticsearch');

  q = require('q');

  chalk = require('chalk');

  mongo = require('mongodb');

  mongodbClient = mongo.MongoClient;

  yargs = require('yargs');

  argv = yargs.usage('Usage: $0 --db \"mongodb://localhost:27017/metrics\" --collection github --elasticHost localhost --elasticIndex github').demand(['db', 'collection', 'elasticHost', 'elasticIndex']).argv;

  cli_arg_mongodb_url = argv.db;

  cli_arg_db_collection = argv.collection;

  cli_arg_es_host = argv.elasticHost;

  cli_arg_es_index = argv.elasticIndex;

  type = 'projects';

  elasticClient = new elasticsearch.Client({
    host: cli_arg_es_host + ':9200'
  });

  collection = mongodbClient.connect(cli_arg_mongodb_url, function(err, db) {
    console.log('');
    console.log('Connecting to mongodb at ', chalk.yellow(cli_arg_mongodb_url));
    if (err) {
      console.log("  unable to access database: " + err);
    }
    collection = db.collection(cli_arg_db_collection);
    console.log('  using collection ', chalk.yellow(cli_arg_db_collection));
    if (!collection) {
      console.log;
      console.log(chalk.red('Fatal error, unable to write to database'));
      console.log;
      return process.exit;
    } else {
      return gatherMetrics();
    }
  });

  gatherMetrics = (function(_this) {
    return function() {
      var full_query, query;
      console.log("request to pull metrics");
      query = {
        "_source": "languages.*",
        "query": {
          "match_all": {}
        },
        "aggs": {
          "total_java_sloc": {
            "sum": {
              "field": "languages.Java"
            }
          },
          "total_c_sloc": {
            "sum": {
              "field": "languages.C"
            }
          },
          "total_cpp_sloc": {
            "sum": {
              "field": "languages.C++"
            }
          },
          "avg_java_sloc": {
            "avg": {
              "field": "languages.Java"
            }
          },
          "avg_c_sloc": {
            "avg": {
              "field": "languages.C"
            }
          },
          "avg_cpp_sloc": {
            "avg": {
              "field": "languages.C++"
            }
          },
          "count_java_projects": {
            "value_count": {
              "field": "languages.Java"
            }
          },
          "count_c_projects": {
            "value_count": {
              "field": "languages.C"
            }
          },
          "count_cpp_projects": {
            "value_count": {
              "field": "languages.C++"
            }
          }
        }
      };
      full_query = {
        index: cli_arg_es_index,
        type: "projects",
        "search_type": "count",
        body: query
      };
      return elasticClient.search(full_query).then(function(body) {
        var data, datestring;
        datestring = new Date().toISOString().replace(/T.*/, '');
        data = [
          {
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
          }
        ];
        return gatherHistogram(data);
      }, function(err) {
        return console.log(chalk.red(err.message));
      });
    };
  })(this);

  calculateBuckets = (function(_this) {
    return function(buckets, callback) {
      var key, large, medium, small, tiny, _i, _len;
      tiny = 0;
      small = 0;
      medium = 0;
      large = 0;
      for (_i = 0, _len = buckets.length; _i < _len; _i++) {
        key = buckets[_i];
        if (key.key < 1000) {
          tiny += key.doc_count;
        } else if (key.key < 10000) {
          small += key.doc_count;
        } else if (key.key < 100000) {
          medium += key.doc_count;
        } else {
          large += key.doc_count;
        }
      }
      return callback(tiny, small, medium, large);
    };
  })(this);

  gatherHistogram = (function(_this) {
    return function(data) {
      var full_query, query;
      console.log("request to pull histogram");
      query = {
        "query": {
          "match_all": {}
        },
        "partial_fields": {
          "partial1": {
            "include": "languages.*"
          }
        },
        "aggs": {
          "java": {
            "histogram": {
              "field": "languages.Java",
              "interval": 1000
            }
          },
          "c": {
            "histogram": {
              "field": "languages.C",
              "interval": 1000
            }
          },
          "cpp": {
            "histogram": {
              "field": "languages.C++",
              "interval": 1000
            }
          }
        }
      };
      full_query = {
        index: cli_arg_es_index,
        body: query
      };
      return elasticClient.search(full_query).then(function(body) {
        return calculateBuckets(body.aggregations.cpp.buckets, function(tiny, small, medium, large) {
          data[0]["cpp_sloc_hist"] = [tiny, small, medium, large];
          return calculateBuckets(body.aggregations.c.buckets, function(tiny, small, medium, large) {
            data[0]["c_sloc_hist"] = [tiny, small, medium, large];
            return calculateBuckets(body.aggregations.java.buckets, function(tiny, small, medium, large) {
              data[0]["java_sloc_hist"] = [tiny, small, medium, large];
              collection.insert(data, {
                w: 1
              }, function(err, docs) {
                if (err) {
                  return console.log("Unable to save record: " + err);
                }
              });
              return process.exit();
            });
          });
        });
      }, function(err) {
        return console.log(chalk.red(err.message));
      });
    };
  })(this);

}).call(this);
