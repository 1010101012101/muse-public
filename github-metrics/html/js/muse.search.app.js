/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
var museSearchApp=angular.module('muse-search-app',['ngRoute']);
museSearchApp.config(function($routeProvider){
   $routeProvider
       .when('/',{
             templateUrl: 'js/views/home.html'
       })
       .when('/search',{
             templateUrl: 'js/views/search.html',
             controller: 'searchController'
       })
       .when('/search/:term',{
             templateUrl: 'js/views/search.html',
             controller: 'searchController'
       })
       .when('/about',{
             templateUrl: 'js/views/about.html'
       })
       .otherwise({
             redirectTo: '/'
       });
});

