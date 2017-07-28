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

// Create the 'example' controller
angular.module('metrics-app').controller('MetricsController', ['$scope', 'Authentication',
   function($scope, Authentication) {
      // Get the user's 'fullName' 
      $scope.name = Authentication.user ? Authentication.user.fullName : 'MEAN Application';
      var size = document.getElementById('size').getContext('2d');
      $scope.sizeChart = new Chart(size).Line(plottingData.projectData, {multiTooltipTemplate: "<%= value %>: <%= datasetLabel %>"});
      var lines = document.getElementById("lines").getContext("2d");
      $scope.lineChart = new Chart(lines).Line(plottingData.totalData, {multiTooltipTemplate: "<%= datasetLabel %>: <%= value %>"});
      var composition = document.getElementById("composition").getContext("2d");
      $scope.compChart = new Chart(composition).Doughnut(plottingData.linePieData, {});
      var hist = document.getElementById("hist").getContext("2d");
      $scope.histChart = new Chart(hist).Bar(plottingData.histData, {multiTooltipTemplate: "<%= value %>: <%= datasetLabel %>"});
   }
]);
