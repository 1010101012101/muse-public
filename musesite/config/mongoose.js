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

// Load the module dependencies
var	config = require('./config'),
	mongoose = require('mongoose');

// Define the Mongoose configuration method
module.exports = function() {
        console.log("mongodb url: " + config.db);
	// Use Mongoose to connect to MongoDB
        var db = mongoose.connect(config.db, function(err) {
            if (err) {
                  console.log("Error connecting to mongodb --- continuing without connection: " + err);
                  return null;
             }
        });

	// Load the 'User' model 
	require('../app/models/user.server.model');

	// Return the Mongoose connection instance
	return db;
};
