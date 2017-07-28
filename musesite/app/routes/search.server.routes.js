/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
'use strict';

var paginate = require('express-paginate');

module.exports = function(app) {

	console.log("search.server.routes ")

	var search = require('app/controllers/search.server.controller.js');
	var cors = require('cors');
	app.use(cors());

	// keep this before all routes that will use pagination
	app.use(paginate.middleware(10, 1000));

	// search Routes
	app.route('/app/search')
		.get(search.list)
		.options(cors());

	app.route('/app/search/:q')
		.get(search.list)
		.options(cors());

	app.route('/app/query/:q')
		.get(search.query)
		.options(cors());

	// app.route('/search/:uuid')
	// 	.get(search.read);

	// Finish by binding the Search middleware
	// app.param('uuid', search.searchByID);
	app.param('q', search.query);
//	app.param('s', search.sort);
//	app.param('q', search.search);
};
