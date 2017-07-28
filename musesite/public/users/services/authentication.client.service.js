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

// Create the 'Authentication' service
angular.module('users').factory('Authentication', [
	function() {
		// Use the rendered user object
		this.user = window.user;

		// Return the authenticated user data
		return {
			user: this.user
		};
	}
]);
