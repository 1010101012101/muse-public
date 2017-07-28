finder-github
=============

Getting your access token setup
-------------------------------

Instructions can be found

    https://github.com/blog/1509-personal-api-tokens

Dependencies
------------

You will need the following

	nodejs
    npm
    grunt
    grunt-cli
    grunt-contrib-coffee
    grunt-contrib-watch


Starting the finder
-------------------

1. Need to setup the node modules and compile the coffeescript to java script, I use a makefile to help out

		make

2. Start up your mongodb instance and create a database

3. Running the application is pretty straight forward, thanks to command line parser yargs

		node js/index.js --token <token here> \
						 --db "mongodb://localhost:27017/github" \
						 --collection github_tester \

4. The last project ID added to the database will be printed with each request to api.github.com.  You may use this to resume a find session via the 'since' argument

		node js/index.js --token <token here> \
						 --db "mongodb://localhost:27017/github" \
						 --collection github_tester \
                	     --since 4303868





