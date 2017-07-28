/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
angular.module('search-app').controller('SearchController',['$scope', '$routeParams', 'SearchFactory', '$http', '$location' ,function($scope, $routeParams, searchFactory, $http, $location){
    $scope.entries;
    $scope.download_link;
    $scope.term = '';
    $scope.sort = 'project.quality_leidos';
    $scope.order = 'desc';
    $scope.full_download = false;
    $scope.query = '';
    $scope.search_size = 0;
    $scope.size_str = '';
    $scope.num_files = 0;
    $scope.sloc = 0;
    $scope.sloc_str = "";
    $scope.files_str = '';
    $scope.full_query = '';
    $scope.javaFilter = false;
    $scope.cFilter = false;
    $scope.cppFilter = false;
    $scope.noneFilter = true;
    $scope.dateSortDsc = false;
    $scope.dateSortAsc = false;
    $scope.sizeSortDsc = false;
    $scope.sizeSortAsc = false;
    $scope.noneSort = true;
    $scope.sorting = 'None';
    $scope.loading = false;
    $scope.queryText =  '';
    $scope.downloading = false;
    $scope.page = 1;
     if ($routeParams.page) {
         $scope.page = $routeParams.page;
    }

    $scope.elasticBuilderDataAll = {};
    $scope.elasticBuilderDataAll.query = [];

    $scope.elasticBuilderDataAll.fields = {
      'project.uuid': { type: 'term' },
      'project.name': { type: 'term' },
      'project.description': { type: 'term' },
      'project.corpus_release': { type: 'multi', choices: [ '1.0', '2.0', 'hackathon', 'phase2' ] },
      'project.readme': { type: 'term' },
      'project.install': { type: 'term' },
      'project.buildStatus': { type: 'multi', choices: [ 'success', 'failure', 'partial', 'no_attempt' ] },
      'project.language': { type: 'multi', choices: [ 'C', 'C++', 'Java' ] },
      'project.languageMain': { type: 'multi', choices: [ 'C', 'C++', 'Java' ] },
      'project.topic': { type: 'multi', choices: [ 'Security', 'Networking', 'Web', 'Imaging', 'UserInterface', 'Xml', 'Database', 'Compression', 'Input-Output', 'Android', 'CyberPhysical' ] },
      'project.total_size': { type: 'number' },
      'project.quality_leidos': { type: 'number' },
      'project.hasBytecode': { type: 'multi', choices: [ 'none', 'single_version', 'multi_version' ] },
      'project.hasObjectFiles': { type: 'multi', choices: [ 'none', 'single_version', 'multi_version' ] },
      'project.site': { type: 'multi', choices: [ 'github', 'google', 'SourceForge','fedora','uciMaven' ] },
      'project.hasSource': { type: 'multi', choices: [ 'none', 'single_version', 'multi_version' ] },
      'project.isAndroidApp': { type: 'term', subType: 'boolean' },
      'project.hasGradleW': { type: 'term', subType: 'boolean' },
      'project.hasGradleBuild': { type: 'term', subType: 'boolean' },
      'project.hasBuildScript': { type: 'term', subType: 'boolean' },
      'project.hasLLVM': { type: 'term', subType: 'boolean' },
      'commit.message': { type: 'term' },
      'commit.id': { type: 'term' },
      'commit.parent_id': { type: 'term' },
      'commit.child_id': { type: 'term' },
      'file.variable.type': { type: 'term' },
      'file.variable.name': { type: 'term' },
      'file.function.return_type': { type: 'term' },
      'file.function.name': { type: 'term'},
      'file.function.parameter_type': { type: 'term'},
     // 'full_path': { type: 'term'},
      'file.file_name': { type: 'term'},
      'file.file_extension': { type: 'term'},
      'file.comment': { type: 'term'},
      'file.class_inherited': { type: 'term'}
    };
    $scope.elasticBuilderDataAll.query = [{"and":[{"term":{"project.name":"*"}},{"terms":{"project.language":["C","C++","Java"]}}]}];
    $scope.elasticBuilderDataAll.needsUpdate = true;
    $scope.queryText = '[{"and":[{"term":{"project.name":"*"}},{"terms":{"project.language":["C","C++","Java"]}}]}]';

    $scope.elasticBuilderData = {};
    $scope.elasticBuilderData.query = [];

    $scope.elasticBuilderData.fields = {
      'name': { type: 'term' },
      'description': { type: 'term' },
      'buildStatus': { type: 'multi', choices: [ 'no_attempt', 'success', 'failure', 'failure_partial' ] },
      'language': { type: 'multi', choices: [ 'C', 'C++', 'Java' ] },
      'total_size': { type: 'number' },
      'hasBytecode': { type: 'multi', choices: [ 'none', 'single_version', 'multi_version' ] },
      'hasObjectFiles': { type: 'multi', choices: [ 'none', 'single_version', 'multi_version' ] },
      'hasSource': { type: 'multi', choices: [ 'none', 'single_version', 'multi_version' ] },
      'isAndroidApp': { type: 'term', subType: 'boolean' }
//      'hasBuildLog': { type: 'term', subType: 'boolean' }
    };

    $scope.elasticBuilderData.query = [{"and":[{"term":{"name":"*"}},{"terms":{"language":["C","C++","Java"]}}]}];
    $scope.elasticBuilderData.needsUpdate = true;

    $scope.elasticBuilderDataFile = {};
    $scope.elasticBuilderDataFile.query = [];

    $scope.elasticBuilderDataFile.fields = {
      'variable.type': { type: 'term' },
      'variable.name': { type: 'term' },
      'function.return_type': { type: 'term' },
      'function.name': { type: 'term'},
      'function.parameter_type': { type: 'term'},
     // 'full_path': { type: 'term'},
      'file_name': { type: 'term'},
      'file_extension': { type: 'term'},
      'comment': { type: 'term'},
      'class_inherited': { type: 'term'}
    };
    
    $scope.elasticBuilderDataCommit = {};
    $scope.elasticBuilderDataCommit.query = [];

    $scope.elasticBuilderDataCommit.fields = {
      'message': { type: 'term' },
      'id': { type: 'term' },
      'parent_id': { type: 'term' },
      'child_id': { type: 'term' }
    };

    searchFactory.getEntries($scope.javaFilter, $scope.cFilter, $scope.cppFilter, $scope.sorting).then(function(results){
            //Success
            console.log("GET ENTRIES");
            $scope.total_results = results.data.hits.total;
            $scope.entries = results.data.hits.hits;
            $scope.search_size = results.data.aggregations.size.value;
            $scope.num_files = results.data.aggregations.files.doc_count;
            $scope.sloc = results.data.aggregations.sloc.value;
            $scope.size_str = bytesToSize($scope.search_size);
            $scope.files_str = addCommas($scope.num_files);
            $scope.sloc_str = addCommas($scope.sloc);
        }, function(results){
            console.log("ERROR getting entries: " + JSON.stringify(results));
        }
    );

    $scope.limit = 10;
    if ($routeParams.limit) {
	 $scope.limit= $routeParams.limit;
    }

    if ($routeParams.term) {
       $scope.term = $routeParams.term
    }

    if ($routeParams.query) {
       $scope.query = $routeParams.query
    }

    $scope.total_pages = 1;

    $scope.searchPage = function (){
      $location.path( '/search' ).replace();
    };

    $scope.textPage = function (){
      $location.path( '/search-text' ).replace();
    };

    function addCommas(nStr)
    {
	nStr += '';
	x = nStr.split('.');
	x1 = x[0];
	x2 = x.length > 1 ? '.' + x[1] : '';
	var rgx = /(\d+)(\d{3})/;
	while (rgx.test(x1)) {
		x1 = x1.replace(rgx, '$1' + ',' + '$2');
	}
	return x1 + x2;
    }    

    function bytesToSize(bytes) {
       if(bytes == 0) return '0 Byte';
       var k = 1024;
       var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
       var i = Math.floor(Math.log(bytes) / Math.log(k));
       return (bytes / Math.pow(k, i)).toPrecision(3) + ' ' + sizes[i];
    }

    function doSearch() {
        searchFactory.searchEntries($scope.term, $scope.javaFilter, $scope.cFilter, $scope.cppFilter, $scope.sorting, $scope.page).then(function(results){
                //Success
                $scope.total_results = results.data.hits.total;
                $scope.entries = results.data.hits.hits;
                $scope.total_pages = Math.ceil($scope.total_results / $scope.limit);
                $scope.search_size = results.data.aggregations.size.value;
                $scope.num_files = results.data.aggregations.files.doc_count;
                $scope.sloc = results.data.aggregations.sloc.value;
                $scope.size_str = bytesToSize($scope.search_size);
                $scope.files_str = addCommas($scope.num_files);
                $scope.sloc_str = addCommas($scope.sloc);
        }, function(results){
                //console.log(JSON.stringify($scope.entries));
            }, function(results){
                console.log("ERROR doing search: " + JSON.stringify(results));
            }
        );
        console.log(JSON.stringify($scope.total_results));        
    }
   

    var str_project_query = '';
    var str_file_query = "";
    var str_commit_query = '';
    var str_all_query = '';
    var fileFilterKeys = ['variable.name', 'variable.type', 'function.return_type', 'function.parameter', 'function.name', 'comment', 'full_path', 'file_extension', 'file_name', 'class_inherited'];
    var commitFilterKeys = ['message', 'id', 'child_id', 'parent_id'];

    var projectFilterKeys = ['name', 'description', 'readme', 'install'];
    var fileFilterKeys2 = ['file.variable.name', 'file.variable.type', 'file.function.return_type', 'file.function.parameter', 'file.function.name', 'file.comment', 'file.full_path', 'file.file_extension', 'file.file_name', 'file.class_inherited'];
    var commitFilterKeys2 = ['commit.message', 'commit.id', 'commit.child_id', 'commit.parent_id'];

    function contains(a, obj) {
       var i = a.length;
       while (i--) {
          if (a[i] === obj) {
           return true;
          }
       }
       return false;
    }

    function updateProjectQuery(key, value){
 	var old_val = '{"term":{"'+key+'":"' + value + '"}}';
    	var new_val= '{"query":{"wildcard":{"name":"'+ value +'"}}}';

        // case sensitive cases
	if (key == 'name' ){
           var enclosed = getEnclosedValue(value);
           if (enclosed) { 
 	      old_val = "{\"term\":{\"" + key + "\":\"\\\"" + enclosed + "\\\"\"}}";
    	      new_val= '{"query":{"wildcard":{"'+ key + '.raw":"'+ enclosed +'"}}}';
           }
           else{
	      new_val = '{"query":{"wildcard":{"' + key + '":"' + value.toLowerCase() + '"}}}';
	   }
	   str_project_query = str_project_query.replace(old_val, new_val);
	   str_all_query = str_all_query.replace(old_val, new_val);
	}
        // phrase matching cases
	if (key == 'description' || key == 'readme' || key == 'install'){
           var enclosed = getEnclosedValue(value);
           if (enclosed) { 
 	      old_val = "{\"term\":{\"" + key + "\":\"\\\"" + enclosed + "\\\"\"}}";
    	      new_val= '{"query":{"match_phrase":{"'+ key + '":"' + enclosed +'"}}}';
           }
           else{
	      new_val = '{"query":{"wildcard":{"' + key + '":"' + value.toLowerCase() + '"}}}';
	   }
	   str_project_query = str_project_query.replace(old_val, new_val);
	   str_all_query = str_all_query.replace(old_val, new_val);
	}
    }

    function updateCommitQuery(key, value){
	var new_val = '{"query":{"wildcard":{"' + key + '":"' + value + '"}}}';
        var old_val = '{"term":{"' + key + '":"' + value + '"}}';

        // need to handle phrase matching on commit messages
	if (key == 'message'){
           var enclosed = getEnclosedValue(value);
           if (enclosed){
              old_val = '{"term":{"' + key + '":"\\"' + enclosed + '\\""}}';
	      new_val = '{"query":{"match_phrase":{"' + key + '":"' + enclosed + '"}}}';
	   }
           else{
	      new_val = '{"query":{"wildcard":{"' + key + '":"' + value.toLowerCase() + '"}}}';
	   }
           str_commit_query = str_commit_query.replace(old_val, new_val);   

           var new_val2 = '{"has_child":{"type":"commit","filter":' + new_val + '}}';
	   str_all_query = str_all_query.replace(old_val, new_val2);
	}
    }

    function updateFileQuery(key, value)
    {
        var path = "";
        var new_val = "";
        var old_val = '{"term":{"' + key + '":"' + value + '"}}';
        // special handling for nested fields
        var split = key.split(".");
        if(split.length > 1){
	   path = split[0];
           // auto toLower all string fields
           if (typeof value === 'string'){
              new_val ='{"query":{"nested":{"path":"' + path + '","query":{"wildcard":{"' + key + '":"' + value.toLowerCase() + '"}}}}}'; 
           }
           else{	
              new_val ='{"query":{"nested":{"path":"' + path + '","query":{"wildcard":{"' + key + '":"' + value + '"}}}}}'; 
	   }
           // need to handle case sensitive searches on certain fields 
	   if (key == 'function.name' || key == 'function.parameter_type' || key == 'function.return_type'  || key == 'variable.name' || key == 'variable.type'){
              var enclosed = getEnclosedValue(value);
              if (enclosed){
                 old_val = '{"term":{"' + key + '":"\\"' + enclosed + '\\""}}';
                 new_val ='{"query":{"nested":{"path":"' + path + '","query":{"wildcard":{"' + key + '.raw":"' + enclosed + '"}}}}}';  
	      }
	   }
	}
        // non-nested file fields
        else{
           // auto toLower all string fields
           if (typeof value === 'string'){
              new_val ='{"query":{"wildcard":{"' + key + '":"' + value.toLowerCase() + '"}}}'; 
	   }
           else{
              new_val ='{"query":{"wildcard":{"' + key + '":"' + value + '"}}}'; 
	   }

           // need to handle case sensitive searches on certain fields 
	   if (key == 'file_name' || key == 'file_extension' || key == 'class_inherited'){
              var enclosed = getEnclosedValue(value);
              if (enclosed){
                 old_val = '{"term":{"' + key + '":"\\"' + enclosed + '\\""}}';
	         new_val = '{"query":{"wildcard":{"' + key + '.raw":"' + enclosed + '"}}}';
	      }
	   }

           // need to handle phrase matching on certain fields 
	   if (key == 'comment'){
              var enclosed = getEnclosedValue(value);
              if (enclosed){
                 old_val = '{"term":{"' + key + '":"\\"' + enclosed + '\\""}}';
	         new_val = '{"query":{"match_phrase":{"' + key + '":"' + enclosed + '"}}}';
	      }
	   }
	}
        str_file_query = str_file_query.replace(old_val, new_val);   

        var new_val2 = '{"has_child":{"type":"file","filter":' + new_val + '}}';
	str_all_query = str_all_query.replace(old_val, new_val2);
    }

    /** Recursively scans a json object */    
    function scan(obj){
    	var k;
    	if (obj instanceof Object) {
           // for each property 
           for (k in obj){
	      if (obj.hasOwnProperty('name')){
                  var enclosed = getEnclosedValue(obj[k]);
 		  var val = '{"term":{"name":"' + obj[k] + '"}}';
    		  var new_val= '{"query":{"wildcard":{"name":"'+ obj[k].toLowerCase() +'"}}}';
                  // check for case sensitive searches
                  if (enclosed) { 
 		     val = "{\"term\":{\"name\":\"\\\"" + enclosed + "\\\"\"}}";
    		     new_val= '{"query":{"wildcard":{"name.raw":"'+ enclosed +'"}}}';
                  }
		  str_project_query = str_project_query.replace(val, new_val);
	      }
	      if (obj.hasOwnProperty('description')){
                  var enclosed = getEnclosedValue(obj[k]);
                  var val = '{"term":{"description":"' + obj[k] + '"}}';
    		  var new_val= '{"query":{"wildcard":{"description":"'+ obj[k].toLowerCase() +'"}}}';
                  // check for phrase matching
                  if(enclosed){
                     val = '{"term":{"description":"\\"' + enclosed + '\\""}}';
    		     new_val= '{"query":{"match_phrase":{"description":"'+ enclosed +'"}}}';
		  }
		  str_project_query = str_project_query.replace(val, new_val);
	      }
              if(contains(fileFilterKeys, k)){
                  updateFileQuery(k, obj[k]);
              }
              if(contains(commitFilterKeys, k)){
                  updateCommitQuery(k, obj[k]);
              }
  
              if (obj.hasOwnProperty(k)){
                  //recursive call to scan property
                  scan( obj[k]);  
              }                
           }
    	}
    }

    /* Recursively scan a json object */    
    function scan2(obj){
    	var k;
    	if (obj instanceof Object) {
           // for each property 
           for (k in obj){

              if(contains(projectFilterKeys, k)){
                  updateProjectQuery(k, obj[k]);
              }
              if(contains(fileFilterKeys, k)){
                  updateFileQuery(k, obj[k]);
              }
              if(contains(commitFilterKeys, k)){
                  updateCommitQuery(k, obj[k]);
              }
  
              if (obj.hasOwnProperty(k)){
                  //recursive call to scan property
                  scan2( obj[k]);  
              }                
           }
    	}
    }

    // translate standard query into ES query 
    function translateQuery(){
        var translated_query = '{"and":';
        var query_project = ($scope.elasticBuilderDataAll.query);
        if(query_project && query_project != ""){
           str_all_query =  JSON.stringify(query_project);
	   console.log("Found project query: " + str_all_query);
//           str_all_query = str_all_query.replace(/project.name/, "project.full_name");
           str_all_query = str_all_query.replace(/project.uuid/, "_id");
           str_all_query = str_all_query.replace(/project./g, "");
           str_all_query = str_all_query.replace(/commit./g, "");
           str_all_query = str_all_query.replace(/file\./g, "");
           query_project = JSON.parse(str_all_query);
           console.log("Query AFTER REPLACE: " + str_all_query);
           if(query_project && query_project != ""){
              scan2(query_project);
              translated_query += str_all_query;
 	   } 
        }
        translated_query +=  '}';

        var sorting = ($scope.sort);
        var order = ($scope.order);
        var sortstr = ',"sort":{"';
        if(sorting && sorting != ""){
          sortstr += sorting;
          sortstr += '":{"order":"';
          if (order && order != ""){
            if (order == "ascending"){
              sortstr += 'asc';
            }
            else{
	      sortstr += 'desc';
	    }
	  }
          else{
            sortstr += 'desc';
          }
          sortstr += '"}}';
          //translated_query += sortstr;
	}
        return translated_query;
    }


    function translateTextQuery(){
        var translated_query = '{"and":';
        var query_project = ($scope.queryText);
        if(query_project && query_project != ""){
           str_all_query = query_project;
	   console.log("Found project query: " + str_all_query);
           str_all_query = str_all_query.replace(/project./g, "");
           str_all_query = str_all_query.replace(/commit./g, "");
           str_all_query = str_all_query.replace(/file./g, "");
           try{
              query_project = JSON.parse(str_all_query);
	   
              if(query_project && query_project != ""){
                scan2(query_project);
                translated_query += str_all_query;
                translated_query +=  '}';
 	      }
           } 
           catch(e){
		alert(e);
                translated_query = null;
	   }
        }
        return translated_query;
    }

    function combineQueries(){
        var query_project = ($scope.elasticBuilderData.query);
        var query_commit = ($scope.elasticBuilderDataCommit.query);
        var query_file = ($scope.elasticBuilderDataFile.query);
        var query_combined = '{"and":[';
        var count = 0;
        str_project_query = "";
        str_file_query = "";
        str_commit_query = "";

        // if Project filters present
        if(query_project && query_project != ""){
           str_project_query =  JSON.stringify(query_project);
           console.log("Found project query: " + str_project_query);
           scan(query_project);
           var proj_obj = '{"and":'+ str_project_query + '}';
           query_combined += proj_obj;
           count++;
        }
        // if Commit filters present
        if(query_commit && query_commit != ""){
           str_commit_query =  JSON.stringify(query_commit);
           console.log("Found commit query: " + str_commit_query );
           scan(query_commit);
           var cquery = '{"has_child":{"type":"commit","filter":{"and":' + str_commit_query + '}}}';
           if(count>0){
                query_combined += "," + cquery;
           }
           else{
                query_combined += cquery;
           }
           count++;
        }
        // if File filters present
        if(query_file && query_file != ""){
           str_file_query =  JSON.stringify(query_file);
           console.log("Found file query: " + str_file_query );
           scan(query_file);
           var fileObj = '{"has_child":{"type":"file","filter":{"and":'+ str_file_query +'}}}'

           if(count>0){
                query_combined +=  "," + fileObj;
           }
           else{
                query_combined += fileObj;
           }
        }
        query_combined += ']}';

        return query_combined;
    }

    // Determine if value is enclosed in double quotes, 
    // if found; return value enclosed
    // if not return empty
    function getEnclosedValue(value){
       var newval;
       if (value.match("^"+"\"") && value.match("\""+"$")) {
          newval = value.substring(1,value.length-1);
       }
       return newval;
    }

    function doQuery() {
        var query_combined = combineQueries();
        console.log("Translated FullQuery: " + query_combined);
        //alert(query_combined);
        $scope.full_query = query_combined;

        searchFactory.queryCorpus(query_combined, $scope.page, $scope.sort, $scope.order).then(function(results){
                //Success
                $scope.total_results = results.data.hits.total;
                $scope.entries = results.data.hits.hits;
                $scope.total_pages = Math.ceil($scope.total_results / $scope.limit);
                $scope.search_size = results.data.aggregations.size.value;
                $scope.num_files = results.data.aggregations.files.doc_count;
                $scope.sloc = results.data.aggregations.sloc.value;
                $scope.size_str = bytesToSize($scope.search_size);
                $scope.files_str = addCommas($scope.num_files);
                $scope.sloc_str = addCommas($scope.sloc);
                console.log("Total: " + $scope.size_str);
        }, function(results){
                console.log(JSON.stringify($scope.entries));
            }, function(results){
                console.log("ERROR doing query: " + JSON.stringify(results));
            }
        );
    }

    function doQueryAdv(){
       var query = translateQuery();
       console.log("Sort term: " + $scope.sort);
       console.log("Translated FullQuery: " + query);
       $scope.full_query = query;      
       //alert(query);
       $scope.loading = true;
      
       searchFactory.queryCorpus(query, $scope.page, $scope.sort, $scope.order).then(function(results){
                //Success
                $scope.total_results = results.data.hits.total;
                $scope.entries = results.data.hits.hits;
                $scope.total_pages = Math.ceil($scope.total_results / $scope.limit);
                $scope.search_size = results.data.aggregations.size.value;
                $scope.num_files = results.data.aggregations.files.doc_count;
                $scope.sloc = results.data.aggregations.sloc.value;
                $scope.size_str = bytesToSize($scope.search_size);
                $scope.files_str = addCommas($scope.num_files);
                $scope.sloc_str = addCommas($scope.sloc);
                console.log("Total: " + $scope.size_str);
       }, function(results){
                console.log(JSON.stringify($scope.entries));
       }, function(results){
                alert("Error doing query");
                console.log("ERROR doing query: " + JSON.stringify(results));
       }).finally(function() {
                // called no matter success or failure
                $scope.loading = false;
                $scope.downloading = false;
       }
       );
    }

    function doTextQueryAdv(){
       var query = translateTextQuery();
       if(query !== null){
       console.log("Translated FullQuery: " + query);
       $scope.full_query = query;      
       //alert(query);
       $scope.loading = true;
      
       searchFactory.queryCorpus(query, $scope.page).then(function(results){
                //Success
                $scope.total_results = results.data.hits.total;
                $scope.entries = results.data.hits.hits;
                $scope.total_pages = Math.ceil($scope.total_results / $scope.limit);
                $scope.search_size = results.data.aggregations.size.value;
                $scope.size_str = bytesToSize($scope.search_size);
                $scope.num_files = results.data.aggregations.files.doc_count;
                console.log("Total: " + $scope.size_str);
       }, function(results){
                console.log(JSON.stringify($scope.entries));
       }, function(results){
                alert("Error doing query");
                console.log("ERROR doing query: " + JSON.stringify(results));
       }).finally(function() {
                // called no matter success or failure
                $scope.loading = false;
                $scope.downloading = false;
       }
       );
       }
    }

    $scope.downloadResults = function() {
        //var query = combineQueries();
//        $scope.downloading = true;        
        console.log("include queries: " + $scope.full_download);
        var query = translateQuery();
        $scope.download_link = searchFactory.downloadResults(query, $scope.page, $scope.full_download);
        console.log("LINK: " + $scope.download_link);
//        $http.get($scope.download_link).
//	success(function(data, status, headers, config) {
    	// this callback will be called asynchronously
    	// when the response is available
//        $scope.downloading = false;
//	var json = JSON.stringify(data);
//	var blob = new Blob(['{sampele: "test"'], { type:"application/json;charset=utf-8;" });
//        saveAs(blob, 'test.json');			
  //	}).
  //	error(function(data, status, headers, config) {
  //      $scope.downloading = false;
    	// called asynchronously if an error occurs
    	// or server returns response with an error status.
 // 	});
/*        searchFactory.downloadResults(query, $scope.page).then(function(results){
	                $scope.toJSON = '';
			var json = JSON.stringify(results.data);
			var blob = new Blob([$scope.toJSON], { type:"application/json;charset=utf-8;" });			
			var downloadLink = angular.element('<a></a>');
                        $scope.url = (window.URL || window.webkitURL | window.location).createObjectURL( blob );
                        downloadLink.attr('href', $scope.url );
                        downloadLink.attr('download', 'muse-search-results-' + new Date().toISOString() + '.json');
			downloadLink[0].click();
                        (window.URL || window.webkitURL).revokeObjectURL( $scope.url );

        }, function(results){
                console.log("ERROR downloading query: " + JSON.stringify(results));
        }).finally(function() {
                // called no matter success or failure
                $scope.downloading = false;
        }
        );
*/
    }
  
    $scope.getLanguageKeys = function(languageObject) {
        return Object.keys(languageObject);
    }

    $scope.findValue = function(enteredValue) {     
        console.log("Searching for = " + enteredValue);
        $scope.term = enteredValue
        $scope.page = 1;
        doSearch();
    }

    $scope.findQuery = function(enteredValue) {     
        $scope.page = 1;
        doQuery();
    }

    $scope.findQueryAdv = function(enteredValue) {     
        $scope.page = 1;
        doQueryAdv();
    }

    $scope.findTextQueryAdv = function(enteredValue) {     
        $scope.page = 1;
        doTextQueryAdv();
    }

    $scope.alertSearch = function() {
       //alert(JSON.stringify($scope.elasticBuilderDataAll.query));
       prompt(JSON.stringify($scope.elasticBuilderDataAll.query) + "\n\nCopy to clipboard: Ctrl+C, Enter",JSON.stringify($scope.elasticBuilderDataAll.query));
    }
    
    $scope.alertSortHelp = function() {
       alert("Quality Scoring Formula: numberCommits(.4), builds(.3), size(.2), stars(.1) ");
       //prompt( + "\n\nCopy to clipboard: Ctrl+C, Enter",JSON.stringify($scope.elasticBuilderDataAll.query));
    }

    $scope.loadSavedJSON = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*json*parser*"}},{"term":{"project.name":"*json*reader*"}},{"term":{"project.name":"*json*library*"}},{"term":{"project.description":"\"json parser\""}},{"term":{"project.description":"\"json reader\""}},{"term":{"file.comment":"\"json parser\""}},{"term":{"file.comment":"\"json reader\""}},{"term":{"project.description":"\"json library\""}}]}];
       $scope.queryText = '[{"or":[{"term":{"project.name":"*json*parser*"}},{"term":{"project.name":"*json*reader*"}},{"term":{"project.name":"*json*library*"}},{"term":{"project.description":"\"json parser\""}},{"term":{"project.description":"\"json reader\""}},{"term":{"file.comment":"\"json parser\""}},{"term":{"file.comment":"\"json reader\""}},{"term":{"project.description":"\"json library\""}}]}]';

      $scope.elasticBuilderDataAll.needsUpdate = true;
      $scope.findQueryAdv();
    }

    $scope.loadSavedDraper2 = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++"]}}]},{"or":[{"term":{"commit.message":"\"off by one\""}},{"term":{"commit.message":"off*by*one*"}},{"term":{"file.comment":"\"off by one\""}},{"term":{"project.name":"offbyone*"}},{"term":{"project.readme":"\"off by one\""}},{"term":{"project.description":"\"off by one\""}},{"term":{"project.description":"offbyone*"}}]}];
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++"]}}]},{"or":[{"term":{"commit.message":"\"off by one\""}},{"term":{"commit.message":"off*by*one*"}},{"term":{"file.comment":"\"off by one\""}},{"term":{"project.name":"offbyone*"}},{"term":{"project.readme":"\"off by one\""}},{"term":{"project.description":"\"off by one\""}},{"term":{"project.description":"offbyone*"}}]}]';

      $scope.elasticBuilderDataAll.needsUpdate = true;
      $scope.findQueryAdv();
    }
       

    $scope.loadSavedAndroid2 = function() {
      $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["Java"]}}]},{"or":[{"term":{"project.name":"*android*"}},{"term":{"project.description":"android*"}},{"term":{"project.isAndroidApp":1}}]}];
      $scope.queryText = '[{"and":[{"terms":{"project.language":["Java"]}}]},{"or":[{"term":{"project.name":"*android*"}},{"term":{"project.description":"android*"}},{"term":{"project.isAndroidApp":1}}]}]';

      $scope.elasticBuilderDataAll.needsUpdate = true;
      $scope.findQueryAdv();
    }


    $scope.loadSavedMatrix = function() {
       $scope.elasticBuilderData.query = [{"or":[{"term":{"name":"*matrix*multiplication*"}},{"term":{"name":"*matrix*lib*"}},{"term":{"name":"*matrix*computation*"}},{"term":{"name":"*affine*"}},{"term":{"name":"*dlib*matrix*"}},{"term":{"description":"\"matrix multiplication\""}},{"term":{"description":"\"matrix library\""}},{"term":{"description":"\"matrix computation\""}},{"term":{"description":"*affine*"}},{"term":{"description":"\"dlib matrix\""}}]}];
       $scope.queryText = [{"or":[{"term":{"name":"*matrix*multiplication*"}},{"term":{"name":"*matrix*lib*"}},{"term":{"name":"*matrix*computation*"}},{"term":{"name":"*affine*"}},{"term":{"name":"*dlib*matrix*"}},{"term":{"description":"\"matrix multiplication\""}},{"term":{"description":"\"matrix library\""}},{"term":{"description":"\"matrix computation\""}},{"term":{"description":"*affine*"}},{"term":{"description":"\"dlib matrix\""}}]}];

       $scope.elasticBuilderData.needsUpdate = true;
       $scope.elasticBuilderDataCommit.query = [];
       $scope.elasticBuilderDataCommit.needsUpdate = true;
       $scope.elasticBuilderDataFile.query = [];
       $scope.elasticBuilderDataFile.needsUpdate = true;
       $scope.findQuery();

    }

    $scope.loadSavedLCS = function() {
       $scope.elasticBuilderData.query = [{"or":[{"term":{"name":"\"*LCS*\""}},{"term":{"name":"*suffix*tree*"}},{"term":{"name":"*longest*common*"}},{"term":{"description":"\"suffix tree\""}},{"term":{"description":"\"longest common\""}}]}];
       $scope.elasticBuilderData.needsUpdate = true;
       $scope.elasticBuilderDataCommit.query = [];
       $scope.elasticBuilderDataCommit.needsUpdate = true;
       $scope.elasticBuilderDataFile.query = [];
       $scope.elasticBuilderDataFile.needsUpdate = true;
       $scope.findQuery();
    }
    $scope.loadSavedLCS2 = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"\"*LCS*\""}},{"term":{"project.name":"*suffix*tree*"}},{"term":{"project.name":"*longest*common*"}},{"term":{"project.description":"\"suffix tree\""}},{"term":{"project.description":"\"longest common\""}},{"term":{"project.readme":"\"longest common\""}},{"term":{"project.readme":"\"suffix tree\""}},{"term":{"file.comment":"\"longest common\""}},{"term":{"file.comment":"\"suffix tree\""}},{"term":{"commit.message":"\"longest common\""}},{"term":{"commit.message":"\"suffix tree\""}}]}];
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"\"*LCS*\""}},{"term":{"project.name":"*suffix*tree*"}},{"term":{"project.name":"*longest*common*"}},{"term":{"project.description":"\"suffix tree\""}},{"term":{"project.description":"\"longest common\""}},{"term":{"project.readme":"\"longest common\""}},{"term":{"project.readme":"\"suffix tree\""}},{"term":{"file.comment":"\"longest common\""}},{"term":{"file.comment":"\"suffix tree\""}},{"term":{"commit.message":"\"longest common\""}},{"term":{"commit.message":"\"suffix tree\""}}]}]';

       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedGraph = function() {
       $scope.elasticBuilderData.query = [{"or":[{"term":{"name":"*graph*algo*"}},{"term":{"name":"*bipartite*"}},{"term":{"name":"*connected*graph*"}},{"term":{"name":"*planar*graph*"}},{"term":{"name":"*cyclic*graph*"}},{"term":{"name":"*hamiltonian*"}},{"term":{"description":"\"graph algorithms\""}},{"term":{"description":"\"graph properties\""}},{"term":{"description":"bipartite*"}},{"term":{"description":"hamiltonian*"}},{"term":{"description":"\"planar graph\""}}]}];
       $scope.elasticBuilderData.needsUpdate = true;
       $scope.elasticBuilderDataCommit.query = [];
       $scope.elasticBuilderDataCommit.needsUpdate = true;
       $scope.elasticBuilderDataFile.query = [];
       $scope.elasticBuilderDataFile.needsUpdate = true;
       $scope.findQuery();
    }


    $scope.loadSavedMatrix = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*matrix*multiplication*"}},{"term":{"project.name":"matrix*library*"}},{"term":{"project.name":"*affine*"}},{"term":{"project.description":"\"matrix multpication\""}},{"term":{"project.description":"\"matrix library\""}},{"term":{"project.description":"\"matrix computation\""}},{"term":{"project.description":"\"dlib matrix\""}},{"term":{"project.description":"affine"}},{"term":{"project.readme":"\"matrix library\""}},{"term":{"project.readme":"\"matrix multiplication\""}},{"term":{"project.readme":"\"matrix computation\""}},{"term":{"project.readme":"affine"}}]}];
       $scope.queryText = '[{"or":[{"term":{"project.name":"*matrix*multiplication*"}},{"term":{"project.name":"matrix*library*"}},{"term":{"project.name":"*affine*"}},{"term":{"project.description":"\"matrix multpication\""}},{"term":{"project.description":"\"matrix library\""}},{"term":{"project.description":"\"matrix computation\""}},{"term":{"project.description":"\"dlib matrix\""}},{"term":{"project.description":"affine"}},{"term":{"project.readme":"\"matrix library\""}},{"term":{"project.readme":"\"matrix multiplication\""}},{"term":{"project.readme":"\"matrix computation\""}},{"term":{"project.readme":"affine"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedGraph = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*graph*"}},{"term":{"project.description":"\"graph properties\""}},{"term":{"project.description":"\"connected graph\""}},{"term":{"project.description":"\"cyclic graph\""}},{"term":{"project.description":"\"planar graph\""}},{"term":{"project.description":"bipartite"}},{"term":{"project.description":"hamiltonian"}},{"term":{"project.readme":"\"connected graph\""}},{"term":{"project.readme":"\"graph properties"}},{"term":{"project.readme":"bipartite"}},{"term":{"project.readme":"hamiltonian"}},{"term":{"project.readme":"\"cyclic graph\""}}]}];
       $scope.queryText = '[{"or":[{"term":{"project.name":"*graph*"}},{"term":{"project.description":"\"graph properties\""}},{"term":{"project.description":"\"connected graph\""}},{"term":{"project.description":"\"cyclic graph\""}},{"term":{"project.description":"\"planar graph\""}},{"term":{"project.description":"bipartite"}},{"term":{"project.description":"hamiltonian"}},{"term":{"project.readme":"\"connected graph\""}},{"term":{"project.readme":"\"graph properties"}},{"term":{"project.readme":"bipartite"}},{"term":{"project.readme":"hamiltonian"}},{"term":{"project.readme":"\"cyclic graph\""}}]}]'; 
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedBresen = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"bresenham*"}},{"term":{"project.name":"line*drawing*"}},{"term":{"project.description":"bresenham*"}},{"term":{"project.description":"\"computer graphics\""}},{"term":{"project.readme":"bresenham*"}},{"term":{"project.description":"\"line drawing\""}},{"term":{"file.comment":"bresenham*"}},{"term":{"commit.message":"bresenham*"}}]}]; 
       $scope.queryText = '[{"or":[{"term":{"project.name":"bresenham*"}},{"term":{"project.name":"line*drawing*"}},{"term":{"project.description":"bresenham*"}},{"term":{"project.description":"\"computer graphics\""}},{"term":{"project.readme":"bresenham*"}},{"term":{"project.description":"\"line drawing\""}},{"term":{"file.comment":"bresenham*"}},{"term":{"commit.message":"bresenham*"}}]}]'; 
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedAES = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"\"*AES*\""}},{"term":{"project.name":"*encryption*"}},{"term":{"project.name":"*cryptography*"}},{"term":{"project.description":"\"fips 197\""}},{"term":{"project.description":"AES"}},{"term":{"project.readme":"AES"}},{"term":{"project.readme":"\"fips 197\""}},{"term":{"project.description":"encryption"}},{"term":{"project.description":"cryptography"}}]}];
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"\"*AES*\""}},{"term":{"project.name":"*encryption*"}},{"term":{"project.name":"*cryptography*"}},{"term":{"project.description":"\"fips 197\""}},{"term":{"project.description":"AES"}},{"term":{"project.readme":"AES"}},{"term":{"project.readme":"\"fips 197\""}},{"term":{"project.description":"encryption"}},{"term":{"project.description":"cryptography"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedTree = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*binary*tree*"}},{"term":{"file.function.name":"*leaves"}},{"term":{"file.function.name":"max*integer"}},{"term":{"file.function.name":"min*integer"}},{"term":{"file.function.name":"is*even"}},{"term":{"file.function.name":"is*odd"}},{"term":{"project.description":"\"binary tree\""}},{"term":{"project.readme":"\"binary tree\""}}]}]; 
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*binary*tree*"}},{"term":{"file.function.name":"*leaves"}},{"term":{"file.function.name":"max*integer"}},{"term":{"file.function.name":"min*integer"}},{"term":{"file.function.name":"is*even"}},{"term":{"file.function.name":"is*odd"}},{"term":{"project.description":"\"binary tree\""}},{"term":{"project.readme":"\"binary tree\""}}]}]'; 
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedGUI = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["Java"]}}]},{"or":[{"term":{"project.name":"*gui*"}},{"term":{"project.name":"*uieditor*"}},{"term":{"project.description":"\"swing gui\""}},{"term":{"project.description":"\"user interface\""}},{"term":{"project.readme":"\"swing gui\""}},{"term":{"project.readme":"\"ui editor\""}},{"term":{"project.description":"gui"}}]}]; 
       $scope.queryText = '[{"and":[{"terms":{"project.language":["Java"]}}]},{"or":[{"term":{"project.name":"*gui*"}},{"term":{"project.name":"*uieditor*"}},{"term":{"project.description":"\"swing gui\""}},{"term":{"project.description":"\"user interface\""}},{"term":{"project.readme":"\"swing gui\""}},{"term":{"project.readme":"\"ui editor\""}},{"term":{"project.description":"gui"}}]}]'; 
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedImageSyn = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*camera*"}},{"term":{"project.name":"*imager*"}},{"term":{"project.name":"*scanner*"}},{"term":{"project.name":"jpeg*"}},{"term":{"project.name":"tiff*"}},{"term":{"project.name":"rgba*"}},{"term":{"project.name":"hdri*"}}]}];
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*camera*"}},{"term":{"project.name":"*imager*"}},{"term":{"project.name":"*scanner*"}},{"term":{"project.name":"jpeg*"}},{"term":{"project.name":"tiff*"}},{"term":{"project.name":"rgba*"}},{"term":{"project.name":"hdri*"}}]}]'; 
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedLCA = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*LCA*query*"}},{"and":[{"term":{"project.description":"LCA"}},{"term":{"project.description":"bender"}}]},{"and":[{"term":{"project.readme":"LCA"}},{"term":{"project.readme":"bender"}}]},{"and":[{"term":{"file.comment":"LCA"}},{"term":{"file.comment":"bender"}}]},{"term":{"project.name":"*LCA*bender*"}}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*LCA*query*"}},{"and":[{"term":{"project.description":"LCA"}},{"term":{"project.description":"bender"}}]},{"and":[{"term":{"project.readme":"LCA"}},{"term":{"project.readme":"bender"}}]},{"and":[{"term":{"file.comment":"LCA"}},{"term":{"file.comment":"bender"}}]},{"term":{"project.name":"*LCA*bender*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedListDirectory = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"traverse*directory"}},{"term":{"project.description":"\"traverse directory\""}},{"term":{"project.readme":"\"traverse directory\""}},{"term":{"file.comment":"\"list directory\""}}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"traverse*directory"}},{"term":{"project.description":"\"traverse directory\""}},{"term":{"project.readme":"\"traverse directory\""}},{"term":{"file.comment":"\"traverse directory\""}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }



    $scope.loadSavedPrimeSieve = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*prime*sieve*"}},{"and":[{"term":{"project.description":"prime"}},{"term":{"project.description":"sieve"}}]},{"and":[{"term":{"project.readme":"prime"}},{"term":{"project.readme":"sieve"}}]},{"and":[{"term":{"file.comment":"prime"}},{"term":{"file.comment":"sieve"}}]}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*prime*sieve*"}},{"and":[{"term":{"project.description":"prime"}},{"term":{"project.description":"sieve"}}]},{"and":[{"term":{"project.readme":"prime"}},{"term":{"project.readme":"sieve"}}]},{"and":[{"term":{"file.comment":"prime"}},{"term":{"file.comment":"sieve"}}]}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedSuffixTree = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*suffix*tree*"}},{"term":{"project.description":"\"suffix tree\""}},{"term":{"project.readme":"\"suffix tree\""}},{"term":{"file.comment":"\"suffix tree\""}}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*suffix*tree*"}},{"term":{"project.description":"\"suffix tree\""}},{"term":{"project.readme":"\"suffix tree\""}},{"term":{"file.comment":"\"suffix tree\""}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadSavedMMInverse = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*inverse*euclid*"}},{"and":[{"term":{"project.description":"inverse"}},{"term":{"project.description":"euclid"}}]},{"and":[{"term":{"project.readme":"inverse"}},{"term":{"project.readme":"euclid"}}]},{"and":[{"term":{"file.comment":"inverse"}},{"term":{"file.comment":"euclid"}}]}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*inverse*euclid*"}},{"and":[{"term":{"project.description":"inverse"}},{"term":{"project.description":"euclid"}}]},{"and":[{"term":{"project.readme":"inverse"}},{"term":{"project.readme":"euclid"}}]},{"and":[{"term":{"file.comment":"inverse"}},{"term":{"file.comment":"euclid"}}]}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadSavedFloodFill = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*flood*fill*"}},{"term":{"project.description":"\"flood fill\""}},{"term":{"project.readme":"\"flood fill\""}},{"term":{"file.comment":"\"flood fill\""}}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*flood*fill*"}},{"term":{"project.description":"\"flood fill\""}},{"term":{"project.readme":"\"flood fill\""}},{"term":{"file.comment":"\"flood fill\""}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadSavedBresenhamCircle = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*bresenham*circle*"}},{"and":[{"term":{"project.description":"bresenham"}},{"term":{"project.description":"circle"}}]},{"and":[{"term":{"project.readme":"bresenham"}},{"term":{"project.readme":"circle"}}]},{"and":[{"term":{"file.comment":"bresenham"}},{"term":{"file.comment":"circle"}}]}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"*bresenham*circle*"}},{"and":[{"term":{"project.description":"bresenham"}},{"term":{"project.description":"circle"}}]},{"and":[{"term":{"project.readme":"bresenham"}},{"term":{"project.readme":"circle"}}]},{"and":[{"term":{"file.comment":"bresenham"}},{"term":{"file.comment":"circle"}}]}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadSavedPointerCorrupt = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"indexoutofbounds"}},{"term":{"project.description":"indexoutofbounds"}},{"term":{"project.readme":"indexoutofbounds"}},{"term":{"file.comment":"indexoutofbounds"}},{"term":{"commit.message":"indexoutofbounds"}}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"indexoutofbounds"}},{"term":{"project.description":"indexoutofbounds"}},{"term":{"project.readme":"indexoutofbounds"}},{"term":{"file.comment":"indexoutofbounds"}},{"term":{"commit.message":"indexoutofbounds"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadSavedUAF = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"use*after*free"}},{"term":{"project.description":"\"use after free\""}},{"term":{"project.readme":"\"use after free\""}},{"term":{"file.comment":"\"use after free\""}},{"term":{"commit.message":"\"use after free\""}}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"project.name":"use*after*free"}},{"term":{"project.description":"\"use after free\""}},{"term":{"project.readme":"\"use after free\""}},{"term":{"file.comment":"\"use after free\""}},{"term":{"commit.message":"\"use after free\""}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadSavedMavlink = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"commit.message":"mavlink"}},{"term":{"file.comment":"mavlink"}},{"term":{"project.name":"*mavlink*"}},{"term":{"project.readme":"mavlink"}},{"term":{"project.description":"mavlink"}}]}] 
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"commit.message":"mavlink"}},{"term":{"file.comment":"mavlink"}},{"term":{"project.name":"*mavlink*"}},{"term":{"project.readme":"mavlink"}},{"term":{"project.description":"mavlink"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }
    $scope.loadSavedAileron = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"commit.message":"aileron"}},{"term":{"file.comment":"aileron"}},{"term":{"project.name":"*aileron*"}},{"term":{"project.readme":"aileron"}},{"term":{"project.description":"aileron"}}]}] 
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"or":[{"term":{"commit.message":"aileron"}},{"term":{"file.comment":"aileron"}},{"term":{"project.name":"*aileron*"}},{"term":{"project.readme":"aileron"}},{"term":{"project.description":"aileron"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }
    $scope.loadSavedWaypoint = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"and":[{"term":{"file.comment":"waypoint"}},{"term":{"file.function.name":"button*"}}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++","Java"]}}]},{"and":[{"term":{"file.comment":"waypoint"}},{"term":{"file.function.name":"button*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }
    $scope.loadSavedHttp = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"terms":{"project.language":["C","C++"]}}]},{"and":[{"term":{"file.comment":"heap"}},{"term":{"project.name":"*http*"}}]}]
       $scope.queryText = '[{"and":[{"terms":{"project.language":["C","C++"]}}]},{"and":[{"term":{"file.comment":"heap"}},{"term":{"project.name":"*http*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadGPS = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*GPS*spoof*"}},{"and":[{"term":{"project.description":"GPS"}},{"term":{"project.description":"spoof"}}]},{"and":[{"term":{"project.readme":"GPS"}},{"term":{"project.readme":"spoof"}}]},{"and":[{"term":{"file.comment":"GPS"}},{"term":{"file.comment":"spoof"}}]},{"and":[{"term":{"commit.message":"GPS"}},{"term":{"commit.message":"spoof"}}]}]}] 
       $scope.queryText = '[{"or":[{"term":{"project.name":"*GPS*spoof*"}},{"and":[{"term":{"project.description":"GPS"}},{"term":{"project.description":"spoof"}}]},{"and":[{"term":{"project.readme":"GPS"}},{"term":{"project.readme":"spoof"}}]},{"and":[{"term":{"file.comment":"GPS"}},{"term":{"file.comment":"spoof"}}]},{"and":[{"term":{"commit.message":"GPS"}},{"term":{"commit.message":"spoof"}}]}]}]'; 
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadSensor = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*sensor*spoof*"}},{"and":[{"term":{"project.description":"sensor"}},{"term":{"project.description":"spoof"}}]},{"and":[{"term":{"project.readme":"sensor"}},{"term":{"project.readme":"spoof"}}]},{"and":[{"term":{"file.comment":"sensor"}},{"term":{"file.comment":"spoof"}}]},{"and":[{"term":{"commit.message":"sensor"}},{"term":{"commit.message":"spoof"}}]}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*sensor*spoof*"}},{"and":[{"term":{"project.description":"sensor"}},{"term":{"project.description":"spoof"}}]},{"and":[{"term":{"project.readme":"sensor"}},{"term":{"project.readme":"spoof"}}]},{"and":[{"term":{"file.comment":"sensor"}},{"term":{"file.comment":"spoof"}}]},{"and":[{"term":{"commit.message":"sensor"}},{"term":{"commit.message":"spoof"}}]}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadAvionics = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*avionic*"}},{"term":{"project.description":"avionics"}},{"term":{"project.readme":"avionics"}},{"term":{"file.comment":"avionics"}},{"term":{"commit.message":"avionics"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*avionic*"}},{"term":{"project.description":"avionics"}},{"term":{"project.readme":"avionics"}},{"term":{"file.comment":"avionics"}},{"term":{"commit.message":"avionics"}}]}]'; 
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadARM = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*ARM*cortex*"}},{"and":[{"term":{"project.description":"ARM"}},{"term":{"project.description":"cortex"}}]},{"and":[{"term":{"project.readme":"ARM"}},{"term":{"project.readme":"cortex"}}]},{"and":[{"term":{"file.comment":"ARM"}},{"term":{"file.comment":"cortex"}}]},{"and":[{"term":{"commit.message":"ARM"}},{"term":{"commit.message":"cortex"}}]}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*ARM*cortex*"}},{"and":[{"term":{"project.description":"ARM"}},{"term":{"project.description":"cortex"}}]},{"and":[{"term":{"project.readme":"ARM"}},{"term":{"project.readme":"cortex"}}]},{"and":[{"term":{"file.comment":"ARM"}},{"term":{"file.comment":"cortex"}}]},{"and":[{"term":{"commit.message":"ARM"}},{"term":{"commit.message":"cortex"}}]}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadRTOS = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"\"*RTOS*\""}},{"term":{"project.description":"RTOS"}},{"term":{"project.readme":"RTOS"}},{"term":{"file.comment":"RTOS"}},{"term":{"commit.message":"RTOS"}},{"term":{"project.readme":"\"real time operating system\""}},{"term":{"project.description":"\"real time operating system\""}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"\"*RTOS*\""}},{"term":{"project.description":"RTOS"}},{"term":{"project.readme":"RTOS"}},{"term":{"file.comment":"RTOS"}},{"term":{"commit.message":"RTOS"}},{"term":{"project.readme":"\"real time operating system\""}},{"term":{"project.description":"\"real time operating system\""}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadROS = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"\"*ROS*\""}},{"term":{"project.description":"ROS"}},{"term":{"project.readme":"ROS"}},{"term":{"file.comment":"ROS"}},{"term":{"commit.message":"ROS"}},{"term":{"project.description":"\"request of service\""}},{"term":{"project.readme":"\"request of service\""}},{"term":{"commit.message":"\"request of service\""}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"\"*ROS*\""}},{"term":{"project.description":"ROS"}},{"term":{"project.readme":"ROS"}},{"term":{"file.comment":"ROS"}},{"term":{"commit.message":"ROS"}},{"term":{"project.description":"\"request of service\""}},{"term":{"project.readme":"\"request of service\""}},{"term":{"commit.message":"\"request of service\""}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadJoystick = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*joystick*"}},{"term":{"project.description":"joystick"}},{"term":{"project.readme":"joystick"}},{"term":{"file.comment":"joystick"}},{"term":{"commit.message":"joystick"}},{"term":{"file.file_name":"*joystick*"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*joystick*"}},{"term":{"project.description":"joystick"}},{"term":{"project.readme":"joystick"}},{"term":{"file.comment":"joystick"}},{"term":{"commit.message":"joystick"}},{"term":{"file.file_name":"*joystick*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadComms = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*communication*"}},{"term":{"project.description":"communication"}},{"term":{"project.readme":"communication"}},{"term":{"file.comment":"communication"}},{"term":{"commit.message":"communication"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*communication*"}},{"term":{"project.description":"communication"}},{"term":{"project.readme":"communication"}},{"term":{"file.comment":"communication"}},{"term":{"commit.message":"communication"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadNavigation = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*navigation*"}},{"term":{"project.description":"navigation"}},{"term":{"project.readme":"navigation"}},{"term":{"file.comment":"navigation"}},{"term":{"commit.message":"navigation"}}]}] 
       $scope.queryText = '[{"or":[{"term":{"project.name":"*navigation*"}},{"term":{"project.description":"navigation"}},{"term":{"project.readme":"navigation"}},{"term":{"file.comment":"navigation"}},{"term":{"commit.message":"navigation"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadHyper = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*hypervisor*"}},{"term":{"project.description":"hypervisor"}},{"term":{"project.readme":"hypervisor"}},{"term":{"file.comment":"hypervisor"}},{"term":{"commit.message":"hypervisor"}}]}] 
       $scope.queryText = '[{"or":[{"term":{"project.name":"*hypervisor*"}},{"term":{"project.description":"hypervisor"}},{"term":{"project.readme":"hypervisor"}},{"term":{"file.comment":"hypervisor"}},{"term":{"commit.message":"hypervisor"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }
    $scope.loadGraph = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*graph*"}},{"term":{"project.description":"graph"}},{"term":{"project.readme":"graph"}},{"term":{"file.comment":"graph"}},{"term":{"commit.message":"graph"}},{"term":{"file.file_name":"*graph*"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*graph*"}},{"term":{"project.description":"graph"}},{"term":{"project.readme":"graph"}},{"term":{"file.comment":"graph"}},{"term":{"commit.message":"graph"}},{"term":{"file.file_name":"*graph*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }
    $scope.loadCompile = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*compile*"}},{"term":{"project.description":"compile"}},{"term":{"project.readme":"compile"}},{"term":{"file.comment":"compile"}},{"term":{"commit.message":"compile"}},{"term":{"file.file_name":"*compile*"}},{"term":{"file.function.name":"*compile*"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*compile*"}},{"term":{"project.description":"compile"}},{"term":{"project.readme":"compile"}},{"term":{"file.comment":"compile"}},{"term":{"commit.message":"compile"}},{"term":{"file.file_name":"*compile*"}},{"term":{"file.function.name":"*compile*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }
    $scope.loadParse = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*parse*"}},{"term":{"project.description":"parse"}},{"term":{"project.readme":"parse"}},{"term":{"file.comment":"parse"}},{"term":{"commit.message":"parse"}},{"term":{"file.file_name":"*parse*"}},{"term":{"file.function.name":"*parse*"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*parse*"}},{"term":{"project.description":"parse"}},{"term":{"project.readme":"parse"}},{"term":{"file.comment":"parse"}},{"term":{"commit.message":"parse"}},{"term":{"file.file_name":"*parse*"}},{"term":{"file.function.name":"*parse*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }
    $scope.loadDS = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*\"data*structure\"*"}},{"term":{"project.description":"\"data structure\""}},{"term":{"project.readme":"\"data structure\""}},{"term":{"file.comment":"\"data structure\""}},{"term":{"commit.message":"\"data structure\""}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*\"data*structure\"*"}},{"term":{"project.description":"\"data structure\""}},{"term":{"project.readme":"\"data structure\""}},{"term":{"file.comment":"\"data structure\""}},{"term":{"commit.message":"\"data structure\""}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadOS = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*operating*system*"}},{"term":{"project.description":"\"operating system\""}},{"term":{"project.readme":"\"operating system\""}},{"term":{"file.comment":"\"operating system\""}},{"term":{"commit.message":"\"operating system\""}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*operating*system*"}},{"term":{"project.description":"\"operating system\""}},{"term":{"project.readme":"\"operating system\""}},{"term":{"file.comment":"\"operating system\""}},{"term":{"commit.message":"\"operating system\""}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadIO = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*input*"}},{"term":{"project.description":"input output"}},{"term":{"project.readme":"input output"}},{"term":{"file.comment":"input output"}},{"term":{"commit.message":"input output"}},{"term":{"file.file_name":"*input*"}},{"term":{"file.file_name":"*output*"}},{"term":{"file.function.name":"*input*"}},{"term":{"file.function.name":"*input*"}},{"term":{"project.name":"*output*"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*input*"}},{"term":{"project.description":"input output"}},{"term":{"project.readme":"input output"}},{"term":{"file.comment":"input output"}},{"term":{"commit.message":"input output"}},{"term":{"file.file_name":"*input*"}},{"term":{"file.file_name":"*output*"}},{"term":{"file.function.name":"*input*"}},{"term":{"file.function.name":"*input*"}},{"term":{"project.name":"*output*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadRun = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*run*time*"}},{"term":{"project.description":"\"run time\""}},{"term":{"project.readme":"\"run time\""}},{"term":{"file.comment":"\"run time\""}},{"term":{"commit.message":"\"run time\""}},{"term":{"file.function.name":"*runtime*"}},{"term":{"project.name":"*runtime*"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*run*time*"}},{"term":{"project.description":"\"run time\""}},{"term":{"project.readme":"\"run time\""}},{"term":{"file.comment":"\"run time\""}},{"term":{"commit.message":"\"run time\""}},{"term":{"file.function.name":"*runtime*"}},{"term":{"project.name":"*runtime*"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }


    $scope.loadString = function() {
       $scope.elasticBuilderDataAll.query = [{"or":[{"term":{"project.name":"*string*"}},{"term":{"project.description":"string"}},{"term":{"project.readme":"string"}},{"term":{"file.comment":"string"}},{"term":{"commit.message":"string"}},{"term":{"file.file_name":"*string*"}},{"term":{"file.function.name":"*string*"}},{"term":{"file.variable.type":"string"}}]}]
       $scope.queryText = '[{"or":[{"term":{"project.name":"*string*"}},{"term":{"project.description":"string"}},{"term":{"project.readme":"string"}},{"term":{"file.comment":"string"}},{"term":{"commit.message":"string"}},{"term":{"file.file_name":"*string*"}},{"term":{"file.function.name":"*string*"}},{"term":{"file.variable.type":"string"}}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }

    $scope.loadFace = function() {
       $scope.elasticBuilderDataAll.query = [{"and":[{"and":[{"terms":{"project.languageMain":["Java"]}},{"terms":{"project.buildStatus":["success"]}},{"term":{"project.isAndroidApp":0}}]},{"or":[{"term":{"project.description":"\"face detection\""}},{"term":{"project.readme":"\"face detection\""}},{"term":{"project.name":"*face*detection*"}},{"term":{"file.comment":"\"face detection\""}}]}]}] 
       $scope.queryText = '[{"and":[{"and":[{"terms":{"project.languageMain":["Java"]}},{"terms":{"project.buildStatus":["success"]}},{"term":{"project.isAndroidApp":0}}]},{"or":[{"term":{"project.description":"\"face detection\""}},{"term":{"project.readme":"\"face detection\""}},{"term":{"project.name":"*face*detection*"}},{"term":{"file.comment":"\"face detection\""}}]}]}]';
       $scope.elasticBuilderDataAll.needsUpdate = true;
       $scope.findQueryAdv();
    }




    $scope.applyJavaFilter = function() {
        $scope.javaFilter = true;
        $scope.cFilter = false;
        $scope.cppFilter = false;
        $scope.noneFilter = false;
        $scope.page = 1;
        doSearch();
    }
  
    $scope.applyCFilter = function() {
        $scope.javaFilter = false;
        $scope.cFilter = true;
        $scope.cppFilter = false;
        $scope.noneFilter = false;
        $scope.page = 1;
        doSearch();
    }
  
    $scope.applyCppFilter = function() {
        $scope.javaFilter = false;
        $scope.cFilter = false;
        $scope.cppFilter = true;
        $scope.noneFilter = false;
        $scope.page = 1;
        doSearch();
    }
  
    $scope.filterNone = function() {
        $scope.javaFilter = false;
        $scope.cFilter = false;
        $scope.cppFilter = false;
        $scope.noneFilter = true;
        $scope.page = 1;
        doSearch();
    }
  
    $scope.sortDateAsc = function() {
        $scope.sorting = 'DateAsc';
        $scope.page = 1;
        $scope.dateSortDsc = false;
        $scope.dateSortAsc = true;
        $scope.sizeSortDsc = false;
        $scope.sizeSortAsc = false;
        $scope.noneSort = false;
        doSearch();
    }
  
    $scope.sortDateDsc = function() {
        $scope.sorting = 'DateDsc';
        $scope.page = 1;
        $scope.dateSortDsc = true;
        $scope.dateSortAsc = false;
        $scope.sizeSortDsc = false;
        $scope.sizeSortAsc = false;
        $scope.noneSort = false;
        doSearch();
    }
  
    $scope.sortSizeAsc = function() {
        $scope.sorting = 'SizeAsc';
        $scope.page = 1;
        $scope.dateSortDsc = false;
        $scope.dateSortAsc = false;
        $scope.sizeSortDsc = false;
        $scope.sizeSortAsc = true;
        $scope.noneSort = false;
        doSearch();
    }
  
    $scope.sortSizeDsc = function() {
        $scope.sorting = 'SizeDsc';
        $scope.page = 1;
        $scope.dateSortDsc = false;
        $scope.dateSortAsc = false;
        $scope.sizeSortDsc = true;
        $scope.sizeSortAsc = false;
        $scope.noneSort = false;
       doSearch();
    }
  
    $scope.sortNone = function() {
        $scope.sorting = 'None';
        $scope.page = 1;
        $scope.dateSortDsc = false;
        $scope.dateSortAsc = false;
        $scope.sizeSortDsc = false;
        $scope.sizeSortAsc = false;
        $scope.noneSort = true;
        doSearch();
    }

    $scope.nextPage = function() {
        $scope.page = $scope.page + 1;
        if ($scope.page > $scope.total_pages) {
            $scope.page = $scope.total_pages;
        }
        doQueryAdv();
    }

    $scope.prevPage = function() {
        if ($scope.page > 1) {
            $scope.page = $scope.page - 1;
        } else {
            $scope.page = 1
        } 
        doQueryAdv();
    }


}]);
