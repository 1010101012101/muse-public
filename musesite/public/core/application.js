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

// Set the main application name
var mainApplicationModuleName = 'mean';

// Create the main application
var mainApplicationModule = angular.module(mainApplicationModuleName, ['ngRoute', 'users', 'search-app', 'metrics-app']);

// Configure the hashbang URLs using the $locationProvider services 
mainApplicationModule.config(['$locationProvider',
	function($locationProvider) {
		$locationProvider.hashPrefix('!');
	}
]);

mainApplicationModule.config(['$compileProvider',
    function ($compileProvider) {
        $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|tel|file|blob):/);
}]);

mainApplicationModule.config(['$httpProvider',
    function ($httpProvider){ 

            $httpProvider.interceptors.push(function($q, $rootScope) {
                return {
                    'request': function(config) {
                        $rootScope.$broadcast('loading-started');
                        return config || $q.when(config);
                    },
                    'response': function(response) {
                        $rootScope.$broadcast('loading-complete');
                        return response || $q.when(response);
                    }
                };
            });

}]);


mainApplicationModule.directive("loadingIndicator", function() {
            return {
                restrict : "A",
                template: "<div>Loading...</div>",
                link : function(scope, element, attrs) {
                    scope.$on("loading-started", function(e) {
                        element.css({"display" : ""});
                    });

                    scope.$on("loading-complete", function(e) {
                        element.css({"display" : "none"});
                    });

                }
            };
});

// Fix Facebook's OAuth bug
if (window.location.hash === '#_=_') window.location.hash = '#!';

// Manually bootstrap the AngularJS application
angular.element(document).ready(function() {
	angular.bootstrap(document, [mainApplicationModuleName]);
});
