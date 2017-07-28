/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
(function() {
  var cli_arg_mongodb_url, mongo, mongodbClient, retrieveMetrics;

  mongo = require('mongodb');

  mongodbClient = mongo.MongoClient;

  retrieveMetrics = function(mongoURL, dbCollection, callback) {
    var collection;
    return collection = mongodbClient.connect(mongoURL, function(err, db) {
      if (err) {
        console.log("  unable to access database: " + err);
      }
      collection = db.collection(dbCollection);
      if (!collection) {
        console.log;
        console.log(chalk.red('Fatal error, unable to write to database'));
        console.log;
        return process.exit;
      } else {
        return collection.find({}).sort({
          date: 1
        }).toArray((function(_this) {
          return function(err, metrics) {
            var avgCLines, avgCppLines, avgJavaLines, cPercent, countCProjects, countCppProjects, countJavaProjects, countProjects, cppPercent, hist, javaPercent, labels, linesData, metric, plottingData, projectData, totalCLines, totalCppLines, totalData, totalJavaLines, totalLines, total_sloc, _i, _len;
            countProjects = {
              fillColor: "rgba(172,194,132,0.4)",
              strokeColor: "#ACC26D",
              pointHighlightFill: "#ACC26D",
              pointHighlightStroke: "rgba(220,220,220,1)",
              label: "Total",
              data: []
            };
            totalLines = {
              label: "Total",
              fillColor: "rgba(255,194,1,0.4)",
              strokeColor: "#ACC26D",
              pointHighlightFill: "#ACC26D",
              pointHighlightStroke: "rgba(220,220,220,1)",
              data: []
            };
            totalJavaLines = {
              fillColor: "rgba(255,194,1,0.1)",
              fillColor: "rgba(172,194,132,0.1)",
              strokeColor: "#F7464A",
              pointHighlightFill: "#F7464A",
              pointHighlightStroke: "rgba(220,220,220,1)",
              label: "Java",
              data: []
            };
            totalCLines = {
              fillColor: "rgba(255,194,1,0.1)",
              strokeColor: "#46BFBD",
              pointHighlightFill: "#46BFBD",
              pointHighlightStroke: "rgba(220,220,220,1)",
              label: "C",
              data: []
            };
            totalCppLines = {
              fillColor: "rgba(255,194,1,0.1)",
              strokeColor: "#FDB45C",
              pointHighlightFill: "#FDB45C",
              pointHighlightStroke: "rgba(220,220,220,1)",
              label: "C++",
              data: []
            };
            avgJavaLines = {
              fillColor: "#48A497",
              strokeColor: "#48A4D1",
              data: []
            };
            avgCLines = {
              fillColor: "#48A497",
              strokeColor: "#48A4D1",
              data: []
            };
            avgCppLines = {
              fillColor: "#48A497",
              strokeColor: "#48A4D1",
              data: []
            };
            countJavaProjects = {
              fillColor: "rgba(172,194,132,0.1)",
              strokeColor: "#F7464A",
              pointHighlightFill: "#F7464A",
              pointHighlightStroke: "rgba(220,220,220,1)",
              label: "Java",
              data: []
            };
            countCProjects = {
              fillColor: "rgba(172,194,132,0.1)",
              strokeColor: "#46BFBD",
              pointHighlightFill: "#46BFBD",
              pointHighlightStroke: "rgba(220,220,220,1)",
              label: "C",
              data: []
            };
            countCppProjects = {
              fillColor: "rgba(172,194,132,0.1)",
              strokeColor: "#FDB45C",
              pointHighlightFill: "#FDB45C",
              pointHighlightStroke: "rgba(220,220,220,1)",
              label: "C++",
              data: []
            };
            javaPercent = {
              color: "#F7464A",
              highlight: "#FF5A5E",
              label: "Java"
            };
            cPercent = {
              color: "#46BFBD",
              highlight: "#5AD3D1",
              label: "C"
            };
            cppPercent = {
              color: "#FDB45C",
              highlight: "#FFC870",
              label: "C++"
            };
            labels = [];
            for (_i = 0, _len = metrics.length; _i < _len; _i++) {
              metric = metrics[_i];
              labels.push(metric.date);
              countProjects.data.push(metric.total_num_projects);
              total_sloc = metric.total_java_sloc + metric.total_c_sloc + metric.total_cpp_sloc;
              totalLines.data.push(Math.round(total_sloc / 1000000000));
              totalJavaLines.data.push(Math.round(metric.total_java_sloc / 1000000000));
              totalCLines.data.push(Math.round(metric.total_c_sloc / 1000000000));
              totalCppLines.data.push(Math.round(metric.total_cpp_sloc / 1000000000));
              avgJavaLines.data.push(Math.round(metric.avg_java_sloc));
              avgCLines.data.push(Math.round(metric.avg_c_sloc));
              avgCppLines.data.push(Math.round(metric.avg_cpp_sloc));
              countJavaProjects.data.push(metric.count_java_projects);
              countCProjects.data.push(metric.count_c_projects);
              countCppProjects.data.push(metric.count_cpp_projects);
            }
            metric = metrics[metrics.length - 1];
            metric.total_java_sloc + metric.total_c_sloc + metric.total_cpp_sloc;
            javaPercent.value = Math.round(metric.total_java_sloc / total_sloc * 100);
            cPercent.value = Math.round(metric.total_c_sloc / total_sloc * 100);
            cppPercent.value = Math.round(metric.total_cpp_sloc / total_sloc * 100);
            linesData = {
              labels: labels,
              datasets: [totalJavaLines, totalCLines, totalCppLines, avgJavaLines, avgCLines, avgCppLines]
            };
            projectData = {
              labels: labels,
              datasets: [countProjects, countCProjects, countJavaProjects, countCppProjects]
            };
            totalData = {
              labels: labels,
              datasets: [totalLines, totalCLines, totalJavaLines, totalCppLines]
            };
            hist = {
              labels: ["0-1k", "1k-10k", "10k-100k", "> 100k"],
              datasets: [
                {
                  label: "C++",
                  fillColor: "rgba(220,220,220,0.2)",
                  strokeColor: "#FDB45C",
                  pointHighlightFill: "#FDB45C",
                  pointHighlightStroke: "#FDB45C",
                  data: metrics[metrics.length - 1].cpp_sloc_hist
                }, {
                  label: "C",
                  fillColor: "rgba(151,187,205,0.2)",
                  strokeColor: "#46BFBD",
                  pointHighlightFill: "#46BFBD",
                  pointHighlightStroke: "#46BFBD",
                  data: metrics[metrics.length - 1].c_sloc_hist
                }, {
                  label: "Java",
                  fillColor: "rgba(151,0,0,0.2)",
                  strokeColor: "#F7464A",
                  pointHighlightFill: "#F7464A",
                  pointHighlightStroke: "#F7464A",
                  data: metrics[metrics.length - 1].java_sloc_hist
                }
              ]
            };
            plottingData = {
              linesData: linesData,
              projectData: projectData,
              totalData: totalData,
              linePieData: [javaPercent, cPercent, cppPercent],
              histData: hist
            };
            return callback(plottingData);
          };
        })(this));
      }
    });
  };

  module.exports = retrieveMetrics;

  cli_arg_mongodb_url = "mongodb://38.100.20.211:27017/metrics";

  retrieveMetrics(cli_arg_mongodb_url, 'growth', function(data) {
    console.log("var plottingData = " + JSON.stringify(data, null, 4));
    return process.exit();
  });

}).call(this);
