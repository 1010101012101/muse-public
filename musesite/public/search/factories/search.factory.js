/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
angular.module('search-app').factory("SearchFactory", ['$http', function($http){

    var SearchFactory = {};

    SearchFactory.getEntries = function(javaFilter, cFilter, cppFilter, sorting){
//        $http.get("search.json")
        console.log('http://38.100.20.211/app/search');
        return $http.get("http://38.100.20.211/app/search");
    }

    function addFilters(javaFilter, cFilter, cppFilter, sorting) {
        var filterParams = "";
        if (javaFilter) {
            filterParams = filterParams + "&lang=Java";
        }
        if (cFilter) {
            filterParams = filterParams + "&lang=C";
        }
        if (cppFilter) {
            filterParams = filterParams + "&lang=" + encodeURIComponent("C++");
        }
        if (sorting != 'None') {
            filterParams = filterParams + "&sort=" + sorting
        }        
    }

    function createSearchUrl(term, javaFilter, cFilter, cppFilter, sorting, page) {
        var filterParams = addFilters(javaFilter, cFilter, cppFilter, sorting);
        var reqUrl = "http://38.100.20.211/app/search/" + term;
        console.log(reqUrl);
        if (page) { 
            reqUrl += "?page=" + page;
        }
        if (filterParams) {
            reqUrl += filterParams;   
        }
        return reqUrl;
    }

    function createQueryUrl(query, page, sort, order) {
//      var filterParams = addFilters(javaFilter, cFilter, cppFilter, sorting);
        var encoded = encodeURIComponent(query);
        //console.log("encoded: " + encoded);
        var reqUrl = "http://38.100.20.211/app/query/q=" + encoded;
        //console.log(reqUrl);
        if (page) { 
            reqUrl += "?page=" + page;
        }
        if (sort) {
            reqUrl += "&sort=" + sort;
            if (order) {
               reqUrl += "&order=" + order;
	    }
            else{
               reqUrl += "&order=desc";
	    }
	}
//        if (filterParams) {
//            reqUrl += filterParams;   
//        }
        return reqUrl;
    }

    SearchFactory.queryEntries = function(query, javaFilter, cFilter, cppFilter, sorting, page) {
        reqUrl = createQueryUrl(query, javaFilter, cFilter, cppFilter, sorting, page);
        console.log(reqUrl)
        return $http.get(reqUrl);
    }

    SearchFactory.queryCorpus = function(query, page, sort, order) {
        console.log("sorting param client: " + sort + " order: " + order);
        reqUrl = createQueryUrl(query, page, sort, order);
        console.log(reqUrl)
        return $http.get(reqUrl);
    }

	SearchFactory.searchEntries = function(term, javaFilter, cFilter, cppFilter, sorting, page) {
        reqUrl = createSearchUrl(term, javaFilter, cFilter, cppFilter, sorting, page);
        console.log(reqUrl)
        return $http.get(reqUrl);
	}

    SearchFactory.downloadResults = function(query, page, full_download) {
        reqUrl = createQueryUrl(query, page);
        reqUrl += "&download=true";
        if (full_download){
           reqUrl += "&full=true"
        }
        console.log(reqUrl)
        return reqUrl;
       // return $http.get(reqUrl);
    }

    return SearchFactory;
}]);


