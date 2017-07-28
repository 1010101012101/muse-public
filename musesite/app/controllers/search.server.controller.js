/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
'use strict';


var errorHandler = require('./errors.server.controller');

var client, elasticsearch, path, es_host, index, performIndex, performSearch, q, type;

elasticsearch = require('elasticsearch');

var fs = require('fs');
path = require('path');

//index = 'briandevjune4';
index = 'corpus12aug';
type = 'project';

var source_fields = ['name', 'description', 'html_url', 'language', 'created_at', 'quality_leidos'];
var download_fields = ['full_name', 'language', 'html_url']; //'site'
var download_fields2 = ['full_name', 'language', 'html_url', 'site', 'buildStatus', 'hasBuildScript', 'hasGradleW', 'isAndroidApp', 'corpus_release', 'quality_leidos', 'hasBytecode', 'hasObjectFiles', 'total_size', 'hasSource']; 

es_host = process.env.ES_1_PORT_9200_TCP_ADDR;
var es_port = process.env.ES_1_PORT_9200_TCP_PORT;

console.log("Elasticsearch server running: " + es_host + ":" + es_port);

client = new elasticsearch.Client({
  host: es_host + ':' + es_port
});

var add_lang_filter = function (query, lang_filter) {
  // Add language filter to the query if defined
  if (lang_filter) { 
    if (typeof lang_filter == 'string' || lang_filter instanceof String) {
       console.log(JSON.stringify('single filter: ' + lang_filter));
       query.query.filtered['filter'] = {exists: {'field': 'languages.' + lang_filter} };
    } else if (lang_filter instanceof Array) {
       console.log(JSON.stringify('array filter: ' + lang_filter));
        //"or": [
        //{ "term": { "info.language": "java"} },
        //{"term": { "info.language": "c"} }
       // ]

       var or_filter = {"or": []};
       lang_filter.map( function(item) {
          console.log(item);
          or_filter.or.push({exists: {'field': 'languages.' + item}});
       })
       query.query.filtered['filter'] = or_filter;
    }
  }
  return query;
}

var add_sort_param = function (query, sort_param) {
  // Add sort param to the query if defined
  if (sort_param) { 
    if (typeof sort_param == 'string' || sort_param instanceof String) {
        if (sort_param === 'DateDsc') {
          query.sort = {"info.created_at": { "order": "desc" } }
        } else if (sort_param === 'DateAsc') {
          query.sort = "info.created_at"
        } else if (sort_param === 'SizeDsc') {
          query.sort = {"info.size": { "order": "desc" } }
        } else if (sort_param === 'SizeAsc') {
          query.sort = "info.size"
        }
    } 
  }
  return query;
}

exports.list = function(req, res) {

  var perPage = req.query.limit;
  var from = (req.query.page-1)*perPage;
//  var sort_param = req.query.sort;
  var download = req.query.download;

//  if (sort_param) {
//    console.log("Soring by: " + sort_param);
//  }

  var full_query, query;
  
  console.log('request to pull index, from ' + from + ', per_page = ' + perPage);
  query = {
    'query': {
      'filtered': {
        'query': {
          'match_all': {}
        }
      }
    },
    "aggs" : {"size" : { "sum" : { "field" : "total_size" }},
              "sloc" : { "sum" : { "field" : "sloc" }},
             "files": { "children": { "type": "file" }, "aggs": { "docFilter": { "filter": {"query": {"match_all": {}}}}}}}
  };

  // Add the sort param
//  query = add_sort_param(query, sort_param);

  if (download === 'true') {
    console.log("downloadSearchResults")
    downloadSearchResults(res, download_fields, index, type, query);
  } else {
    console.log("standardSearch")
    standardSearch(res, source_fields, index, type, from, perPage, query);
  }
};

exports.read = function(req, res) {
  res.jsonp(req.insert);
};

function standardSearch(res, source_fields, index, type, from, perPage, query) {
  var full_query = {
    _source: true, //source_fields,
    index: index,
    type: type,
    from: from,
    size: perPage,
    body: query
  };

  console.log('full query to ES' + query);

  client.search(full_query).then(function(body) {
     for( var i=0, l=body.hits.hits.length; i<l; i++ ) {
       var elems = body.hits.hits[i]._id.split('-');
       var ltrs = elems[0].split('');
       body.hits.hits[i]._source['path'] = path.join(ltrs[0],ltrs[1],ltrs[2],ltrs[3],ltrs[4],ltrs[5],ltrs[6],ltrs[7],body.hits.hits[i]._id,body.hits.hits[i]._id + '_code.tgz');
     }
     res.json(body);
  }, function(err) {
    res.status(400).send({
      message: errorHandler.getErrorMessage(err)
    });
  });
};

function downloadSearchResults(res, download_fields, index, type, query) {
  var allHits = [];
  var full_query = {
    _source: download_fields,
    index: index,
    type: type,
    search_type: 'scan',
    size: 1000,
    scroll: '30s',
    body: query
  };

  // first we do a search, and specify a scroll timeout
  client.search(full_query, function getMoreUntilDone(error, response) {
    if (response) {
      //console.log("RESPONSE: " + JSON.stringify(response));
      console.log("------------------------------------");
      // collect the fields from each response
      if (response.hits){

       for( var i=0, l=response.hits.hits.length; i<l; i++ ) {
         //console.log('pushing: ' + JSON.stringify(response.hits.hits[i]._source));
         var elems = response.hits.hits[i]._id.split('-');
         var ltrs = elems[0].split('');
         response.hits.hits[i]._source['path'] = path.join(ltrs[0],ltrs[1],ltrs[2],ltrs[3],ltrs[4],ltrs[5],ltrs[6],ltrs[7],response.hits.hits[i]._id,response.hits.hits[i]._id + '_code.tgz');
         allHits.push(response.hits.hits[i]._source);
       }
       //console.log("allHits size: " + allHits.length + " waiting for " + response.hits.total)

       if (response.hits.total !== allHits.length) {
        // now we can call scroll over and over
        client.scroll({
          scrollId: response._scroll_id,
          scroll: '30s'
        }, getMoreUntilDone);
        } 
        else {
          console.log('Got all results for download of results json.  Item count: ', allHits.length);
          var results = {'total': allHits.length}
          results['results'] = allHits;
          res.type('application/json');
          res.attachment('muse-search-results-' + new Date().toISOString() + '.json');
          res.json(results);
        }
      }
      else{
        console.log("resonse to download query was null")
        var results = {'total': 0}
        res.json(results);
      }
    } else {
      console.log("resonse to download query was null")
    }
  });
};

exports.search = function(req, res, next, search_term) {

  var perPage = req.query.limit;
  var from = (req.query.page-1)*perPage;
  var lang_filter = req.query.lang;
  var sort_param = req.query.sort;
  var download = req.query.download;
  console.log(JSON.stringify(req.query))

  var query;
  query = {
    'query': {
      'filtered': {
        'query': {
          'match': {
            '_all': search_term
          }
        }
      }
    }
  };
 
  // Add the language filter
  query = add_lang_filter(query, lang_filter);

  // Add the sort param
  query = add_sort_param(query, sort_param);

  if (download === 'true') {
    console.log("===downloadSearchResults")
    downloadSearchResults(res, download_fields, index, type, query);
  } else {
    //console.log("standardSearch: " + JSON.stringify(query))
    standardSearch(res, source_fields, index, type, from, perPage, query);
  }
};

exports.query = function(req, res, next, term) {
  var perPage = req.query.limit;
  var query1 = req.query;
  var sort = req.query.sort;
  var direction = req.query.order;
  var sorting; //= "{\"" + sort + "\":{\"order\":\"" + order + "\"}}"
  var addr = req.connection.remoteAddress;
  var from = (req.query.page-1)*perPage;
  var download = req.query.download;
  var full = req.query.full; // include additional queries in results
  var query1 = term.substring(2);
  var query_full, query_download;
  if (sort){
    sorting = sort + ":" + direction;
  }

  query_full = { 
    "query": {
      "filtered": {
        "query": {
          "match_all": {}
        },
        "filter": JSON.parse(query1)
      }        
    },
    "aggs" : {"size" : { "sum" : { "field" : "total_size" }},
              "sloc" : { "sum" : { "field" : "sloc" }},
              "files": { "children": { "type": "file" }, "aggs": { "docFilter": { "filter": {"query": {"match_all": {}}}}}}}
  };
  
  query_download = { 
    "query": {
      "filtered": {
        "query": {
          "match_all": {}
        },
        "filter": JSON.parse(query1)
      }        
    }
  };
  //console.log("FULL_QUERY: " + JSON.stringify(query_full));
  //  query = add_sort_param(query, sort_param);

  // Save search to file for tracking purposes along with remote ip address
  //console.log("URL: " + req.originalUrl);
  //console.log("IP: " + req.ip);

  //fs.appendFile("app/searches.log", addr + ": " + JSON.stringify(query_full) + "\n", function(err) {
  //  if(err) {
  //      return console.log(err);
  //  }
  //  console.log("The search was saved to app/searches.log");
  //});

  if (download === 'true') {
    console.log("downloadSearchResults");
    //console.log("QUERYdownload: " + JSON.stringify(query_download));
    // download with full queries in results
    if (full){
      downloadSearchResults(res, download_fields2, index, type, query_download);
    // else download lite version of queries
    } else{
      downloadSearchResults(res, download_fields, index, type, query_download);
    }
  } else {
    console.log("standardQuery: ");
    querySearch(res, index, type, from, perPage, query_full, sorting);
  }
}

function querySearch(res, index, type, from, perPage, query_full, sorting) {
  //query_full = query_full.replace(/'/gi, "\"");
  var full_query;
  if (sorting){
    full_query = {
      _sources: true,
      index: index,
      type: type,
      from: from,
      size: perPage,
      sort: sorting,
      body: query_full
    };
  }
  else{
    full_query = {
      _sources: true,
      index: index,
      type: type,
      from: from,
      size: perPage,
      body: query_full
    };
  }
  console.log("QUERY_SEARCH: " + JSON.stringify(full_query));

  client.search(full_query).then(function(body) {
     var before = Date.now();
     for( var i=0, l=body.hits.hits.length; i<l; i++ ) {
       var elems = body.hits.hits[i]._id.split('-');
       var ltrs = elems[0].split('');
       body.hits.hits[i]._source['path'] = path.join(ltrs[0],ltrs[1],ltrs[2],ltrs[3],ltrs[4],ltrs[5],ltrs[6],ltrs[7],body.hits.hits[i]._id,body.hits.hits[i]._id + '_code.tgz');
     }
     var after = Date.now()
     console.log("Time to create path: " + after + " - " + before);
     res.json(body);
  }, function(err) {
    res.status(400).send({
      message: errorHandler.getErrorMessage(err)
    });
  });
};


