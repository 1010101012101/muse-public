/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
museSearchApp.factory("searchService", function($http){
    var _entries = [];

    var _getEntries = function(javaFilter, cFilter){
//        $http.get("search.json")
        $http.get("https://corpus.museprogram.org/app/search")
            .then(function(results){
                //Success
                angular.copy(results.data.hits, _entries); //this is the preferred; instead of $scope.entries = result.data
            }, function(results){
                alert("ERRRO GETTING DATA");
            })
    }

	 var _searchEntries = function(term, javaFilter, cFilter, page) {
        var filterParams = "";
        if (javaFilter) {
            filterParams = filterParams + "&lang=java";
        }
        if (cFilter) {
            filterParams = filterParams + "&lang=c";
        }
        var reqUrl = "https://corpus.museprogram.org/app/search/" + term;
        if (page) { 
            reqUrl += "?page=" + page;
        }
        if (filterParams) {
            reqUrl += filterParams;   
        }
        console.log(reqUrl)
        // $http.get("https://corpus.museprogram.org/app/search/" + term + "?page=" + page + filterParams)
        $http.get(reqUrl)
            .then(function(results){
                //Success
                angular.copy(results.data.hits, _entries); //this is the preferred; instead of $scope.entries = result.data
            }, function(results){
                alert("ERRRO GETTING DATA");
            })
	 }

    return{
        entries: _entries,
        getEntries: _getEntries,
        searchEntries: _searchEntries
    };
});


