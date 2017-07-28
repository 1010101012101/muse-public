/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
museSearchApp.controller('searchController',['$scope', '$routeParams', 'searchService' ,function($scope, $routeParams, searchService){
    $scope.term = '';
    $scope.javaFilter = false;
    $scope.cFilter = false;
    $scope.page = 1;
     if ($routeParams.page) {
         $scope.page = $routeParams.page;
    }

	 searchService.getEntries($scope.javaFilter, $scope.cFilter);
	 $scope.entries = searchService.entries;

    console.log(JSON.stringify($scope.page));

    $scope.limit = 10;
	 if ($routeParams.limit) {
		 $scope.limit= $routeParams.limit;
	 }
    if ($routeParams.term) {
       $scope.term = $routeParams.term
    }
    console.log(JSON.stringify($scope.term));
	 
    $scope.findValue = function(enteredValue) {     
        console.log("Searching for = " + enteredValue);
        $scope.term = enteredValue
        $scope.page = 1;
        searchService.searchEntries($scope.term, $scope.javaFilter, $scope.cFilter, $scope.page);
        $scope.entries = searchService.entries;
    }
  
    $scope.nextPage = function() {
        $scope.page = $scope.page + 1;
        searchService.searchEntries($scope.term, $scope.javaFilter, $scope.cFilter, $scope.page);
	     $scope.entries = searchService.entries;
    }

    $scope.prevPage = function() {
        if ($scope.page > 1) {
            $scope.page = $scope.page - 1;
        } else {
            $scope.page = 1
        } 
        searchService.searchEntries($scope.term, $scope.javaFilter, $scope.cFilter, $scope.page);
	     $scope.entries = searchService.entries;
    }

}]);
