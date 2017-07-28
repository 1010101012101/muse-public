##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# required modules
chalk = require 'chalk'
yargs = require 'yargs'
octonode = require 'octonode'
uuid = require 'uuid'

# local required modules
GitCrawler = require './GitCrawler'

# Command line arguments
argv = yargs
    .usage('Usage: $0 --token 377sdgsr32r3afpafsp --project asdf/asdf --out /datastore')
    .demand(['token','project','out'])
    .argv;

token = argv.token
project = argv.project
download_path = argv.out


# Check for required software
required_sw = ["git"]
for app in required_sw
		if not which app
			console.log chalk.red 'Fatal error: requires ' + app


# Display download location
process.title = "github-downloader";
console.log ''
console.log 'Projects will be downloaded to:'
console.log '  ', chalk.yellow download_path

github = octonode.client token
	
gc = GitCrawler(github, download_path)

console.log ''
id = uuid.v4()
console.log '  generating a new uuid: '+ id 
console.log ''
gc.download project, id, () ->
	console.log chalk.bold 'done'
