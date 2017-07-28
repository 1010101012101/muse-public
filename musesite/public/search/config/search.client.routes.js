/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
// Invoke 'strict' JavaScript mode
'use strict';

angular.module('search-app').config(function($routeProvider){
   $routeProvider
       .when('/search',{
             templateUrl: 'search/views/search.alt.html',
             controller: 'SearchController'
       })
       .when('/search/:term',{
             templateUrl: 'search/views/search.html',
             controller: 'SearchController'
       })
       .when('/search-adv',{
             templateUrl: 'search/views/search.adv.html',
             controller: 'SearchController'
       })
       .when('/search-text',{
             templateUrl: 'search/views/search.text.html',
             controller: 'SearchController'
       })
       .when('/help',{
             templateUrl: 'search/views/help.html'
       })
       .when('/about',{
             templateUrl: 'search/views/about.html'
       })
       .otherwise({
             redirectTo: '/'
       });
});
