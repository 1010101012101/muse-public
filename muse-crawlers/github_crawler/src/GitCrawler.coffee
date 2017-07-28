##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Requiring modules
octonode = require 'octonode'
async = require 'async'
chalk = require 'chalk'
fs = require 'fs'
require 'shelljs/global'

# Initiate class
class GitCrawler

	constructor: (@client, @path) ->
	
	getPath = (download_path, uuid) ->
		res = uuid.split("")
		res_path = ''
		for element in res when _i < 8
			res_path += res[_i] + '/';
		return download_path + '/' + res_path + uuid


	# Do a full download of all metadata and clone the repo
	download: (name, uuid, cb) ->
		#mb Gets repo name
		gitrepo = @client.repo name
		#mb Gets download path
		download_path = @path
		#mb Gets repo info
		gitrepo.info (err, data, headers) ->
			if err
				console.log chalk.red 'Unable to get info on project'
				cb null
				return
			levelzero = data

			# Welcome
			#mb Write to console project name and language
			console.log '  Crawling Github Project: ', chalk.cyan name
			console.log ''

			console.log '  main language: ' + data.language
			isJcProject = false;
			if data.language == 'Java' || data.language == 'C++' || data.language == 'C'
				isJcProject = true;

			# Check for language
			gitrepo['languages'] (err, data, headers) ->
			#mb If not a language or err write to console
				if !data or err
					console.log '  unable to get language information, bailing...'
					cb null
					return

				if uuid
					#mb Converts language to JSON string
					console.log('  contains languages: ' + JSON.stringify(data)); 
					console.log ''	
					if !( data['C'] or data['C++'] or data['Java']) && (!isJcProject)
						console.log '  does not appear to be a C/C++/Java project, bailing...'
						cb null
						return

				# Setup paths
				#mb project_path = download_path including the uuid
				if uuid
					project_path =  getPath(download_path, uuid)
				else
					console.log '  no UUID given for project, bailing...'	
					cb  null
					return
				#mb Create directories
				module_path = project_path
				mkdir '-p', project_path
				mkdir '-p', project_path + '/github'
			    
			    # Download code
				console.log '  Downloading code...'
				console.log ''
				#mb exec finds match in string while levelzero stores the webpage elements and the module_path is the
				#mb source file location
				if (exec 'git clone --bare ' + levelzero.html_url + '.git ' + module_path + '/bare_repo').code != 0
					console.log chalk.red '  Failed to checkout'
					cb null
					return
				if (exec 'git clone --depth=1 ' + levelzero.html_url + '.git ' + module_path + '/latest').code != 0
					console.log chalk.red '  Failed to checkout'
					cb null
					return
					
				console.log ''
				console.log '  code download done'
				console.log ''
				
				#mb Create array called crawler_metadata_array
				crawler_metadata_array = new Array()
				#mb async.series is a collection of tasks where each one runs after the previous has completed
				async.series [
					(done) =>
					#mb Download metadata and append to array. Calls DownloadData initiated below
						downloadData module_path, gitrepo, 'info', (err) =>
							crawler_metadata_array.push './github/info.json'
							done null
						,
					(done) =>
						downloadData module_path, gitrepo, 'contributors', (err) =>
							crawler_metadata_array.push './github/contributors.json'
							done null
						,
					(done) =>
						downloadData module_path, gitrepo, 'languages', (err) =>
							crawler_metadata_array.push './github/languages.json'
							done null
						,
					(done) =>
						downloadData module_path, gitrepo, 'forks', (err) =>
							crawler_metadata_array.push './github/forks.json'
							done null
						,
					(done) =>
						downloadData module_path, gitrepo, 'tags', (err) =>
							crawler_metadata_array.push './github/tags.json'
							done null
						,
					(done) =>
						downloadData module_path, gitrepo, 'releases', (err) =>
							crawler_metadata_array.push './github/releases.json'
							done null
						,
					(done) =>
						downloadDataPages module_path, gitrepo, 'branches', (err) =>
							crawler_metadata_array.push './github/branches.json'
							done null
						,
					(done) =>
						downloadDataPages module_path, gitrepo, 'labels', (err) =>
							crawler_metadata_array.push './github/labels.json'
							done null
						,
					(done) =>
						downloadDataPages module_path, gitrepo, 'milestones', (err) =>
							crawler_metadata_array.push './github/milestones.json'
							done null
						,
					(done) =>
						downloadDataPages module_path, gitrepo, 'prs', (err) =>
							crawler_metadata_array.push './github/prs.json'
							done null
						,
					(done) =>
						downloadDataPages module_path, gitrepo, 'issues', (err) =>
							crawler_metadata_array.push './github/issues.json'
							done null
						,
					(done) =>
						downloadDataPages module_path, gitrepo, 'commits', (err) =>
							crawler_metadata_array.push './github/commits.json'
							done null
						,
					(done) =>
						downloadDataPages module_path, gitrepo, 'stargazers', (err) =>
							crawler_metadata_array.push './github/stargazers.json'
							done null
						,
					(done) =>
						#mb date formatting
						datestamp = new Date().toISOString()
						#Top level information to add to each project for internal purposes
						index = {
							"name": levelzero.full_name,
							"site": "github",
							"repo": "github",
							"on_disk_ver": "1.2",
							"corpus_release": "2.0",
							"crawled_date": datestamp,
							"uuid": uuid,
							"site_specific_id": levelzero.id,
							"code": "./latest",
							"crawler_metadata": crawler_metadata_array,
							"git_bare_repo": "./bare_repo"
						}

						datastr = JSON.stringify index, null, 4
						#mb writes data to file, replacing the file if it already exists
						fs.writeFile  module_path+'/index.json', datastr, (err) =>
						    console.log chalk.red '    Error: ', err if err
							done null
							cb null
							return
				]



downloadData = (module_path, gitrepo, name, done) ->
	#mb Function being called from the series that downloads metadata and creates .json files
	file = module_path + '/github/' + name + '.json'
	console.log '  ' + 'Writing github ' + name + ' metadata to: '
	console.log '    ', chalk.yellow file

	gitrepo[name] (err, data, headers) ->
		#mb Error handling. Output to console received null
		if !data
			console.log chalk.yellow '      received null' 
			return done null

		console.log '      received ' + data.length + ' results'
		datastr = JSON.stringify data

		fs.writeFile file, datastr, (err) ->
	    	console.log chalk.red '      Error: ', err if err
	    	done null


downloadDataPageN = (page, file, gitrepo, name, done) ->
	#mb If page does not have a next section
	# Get page
	gitrepo[name] page, 100, (err, data, headers) ->
		#mb Error handling
		if !data
			console.log chalk.yellow '      received null' 
			return done null

		# Show user progress
		console.log '      page ' + page + ': ' + data.length + ' results'
		page++

		# Write out the array and we are done
		datastr = JSON.stringify data
		fs.appendFile file, datastr, (err) ->
			console.log chalk.red '      Error: ', err if err

		# If there is another page then pass data to next call
		if data.length == 100 
			downloadDataPageN page, file, gitrepo, name, done
		else
			done null


downloadDataPages = (module_path, gitrepo, name, done) ->

	# We will write this under a github/<name>.json
	file = module_path + '/github/' + name + '.json'
	console.log '  ' + 'Writing github ' + name + ' metadata to: '
	console.log '    ', chalk.yellow file

	# Get page
	gitrepo[name] 1, 100, (err, data, headers) ->

		if !data
			console.log chalk.yellow '      received null' 
			return done null

		# Show user progress
		console.log '      page 1: ' + data.length + ' results'

		# Write out the array and we are done
		datastr = JSON.stringify data
		fs.writeFile file, datastr, (err) ->
			console.log chalk.red '      Error: ', err if err

		# If there is another page then pass data to next call
		if data.length == 100
			downloadDataPageN 2, file, gitrepo, name, done
		else
			done null


#Seems to not be called and unused
printResponse = (err, data, headers) ->
	console.log util.inspect data
	if data == null
		console.log '{}'
	else
		for item in data
			console.log item


# Export modules
module.exports = (token, download_path) ->
  new GitCrawler(token, download_path)

