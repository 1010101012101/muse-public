##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
'''
Created on May 18, 2017

@author: marioborroto & Nate
'''
import argparse
import sys
import numbers
import subprocess
import readline
#sys.path.insert(0, 'metadata-generator/')
from sourceforge_crawler import sfCrawler 

redisHost = '127.0.0.1'
redisdb = '9'
mongoHost = '127.0.0.1'
mongodb = 'corpus'
mongocol = 'corpus1'

# write out a custom fig file based on crawler type user selects
def write_file(crawl_type, value, output, token):
    value= str(value)
    print (crawl_type + " " + value + " " + token + " " + redisHost + " " + mongoHost)
    name = "crawler"
    if value:
       value = "\""+value+"\""
    else:
       value = ""

    if (crawl_type == "single"):
        name="crawler"
        script = "./js/gitdownload.js --project "       
    elif (crawl_type == "search"):
        name="crawler"
        script = "./js/githubSearch.js --query "
    elif (crawl_type == "file"):
        name="crawler"
        script = "./js/githubFile.js --filename "
    elif (crawl_type == "finder"):
        name="finder"
        script = "./js/index.js --since "
    else:
        name="crawler"
        script = "./js/index.js"

    filestr = name + "custom:\n  build: .\n  working_dir: /leit/github-" + name + "\n  command: node " + script +  value + " --token " + token + " --mongoDb \"mongodb://" + mongoHost + ":27017/" + mongodb + "\" --mongoCollection \"" + mongocol + "\" --redisHost " + redisHost + " --redisDb " + redisdb+ " --out " + output + "\n# mount all the application code into the container\n# if a new directory is added in public this list needs to be updated\n# and the container rebuilt (fig build)\n  volumes:\n    - \".:/leit/github-" + name + "\"\n    - \"/data:data\"\n  environment:\n    NODE_ENV: development\n    NODE_PATH: /leit/nodeapp\n# Either set these env vars to the port and host of the mongo and ES\n# server or use the containerized versions of these defined in the db\n# and es services below\n    DB_1_PORT_27017_TCP_ADDR: " + mongoHost + "\n    DB_1_PORT_27017_TCP_PORT: 27017\n    REDIS_1_PORT_6379_TCP_ADDR: " + redisHost + "\n    REDIS_1_PORT_6379_TCP_PORT: 6379\n"

    f = open('github_'+ name + '/fig-custom.yml', 'w')
    f.write(filestr)  # python will convert \n to os.linesep
    f.close() 

def askUser(question):
    try:
       readline.parse_and_bind("tab: complete")
       project = raw_input(question)
    except NameError:
       project = input(question)
    return project


class MyParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)
        
parser = MyParser(formatter_class=argparse.RawTextHelpFormatter, description='Crawl GitHub or SourceForge repository.\n')
parser.add_argument("--github", help="Specify the type of Github crawl to perform(single, search, or file)", metavar="crawl-type", action="store", nargs="?", const="default")
parser.add_argument("--sourceforge", help="Specify the type of SourceForge crawl to perform", metavar="crawl-type", action="store", nargs="?", const="default")
parser.add_argument("--out", help="Specify the output path to download projects to", metavar="path", action="store", nargs="?")
parser.add_argument("--filename", help="Specify the relative filepath containing projects you wish to crawl.  See directedDownload subfolder for examples", metavar="path", action="store", nargs="?")
parser.add_argument("--startID", help="integer specifying the starting SourceForge project id to crawl from", type=int, metavar="projectID", action="store", nargs="?", default=1)
parser.add_argument("--redis", help="Specify the host of the redis db (default:localhost)", metavar="redis-host", action="store", nargs="?", default="127.0.0.1")
parser.add_argument("--redisdb", help="Specify the redis db (default:9)", type=int, metavar="redis-db", action="store", nargs="?", default="9")
parser.add_argument("--mongo", help="Specify the host of the mongo db (default:localhost)", metavar="mongo-host", action="store", nargs="?", default="127.0.0.1")
parser.add_argument("--mongodb", help="Specify the mongo database name to store github projects info (default:corpus)", metavar="mongo-db", action="store", nargs="?", default="corpus")
parser.add_argument("--mongocol", help="Specify the mongo table name to store projects info (default:corpus1)", metavar="collection-name", action="store", nargs="?", default="corpus1")
parser.add_argument("--token", help="github access token (necessaary to crawl github)", type=str, metavar="git-token", action="store", nargs="?")
parser.add_argument("--since", help="used by github finder to determine what project id to start from", type=int, metavar="project-id", action="store", nargs="?", default=0)
args = parser.parse_args()
github = args.github
output = args.out
filename = args.filename
sourceforge = args.sourceforge
redisHost = args.redis
redisdb = str(args.redisdb)
mongoHost = args.mongo
mongodb = args.mongodb
mongocol = args.mongocol
token = args.token
since = str(args.since)
try:
   startID = int(args.startID)
except ValueError:
   print("SF startID is not an integer: " + args.startID)
   parser.print_help()
   sys.exit(1)

if len(sys.argv) == 1:
    parser.print_help()
    sys.exit(1)

if args:
    if github:
        if not token:
           print ("No Github access token was supplied for Github crawl")
           parser.print_help()
           sys.exit(1)
        if (github !='finder') and  (not output):
           print ("No --out  folder was supplied for project downlaod")
           parser.print_help()
           sys.exit(1)
        if github == "finder":
           print ("Running Github Finder...")
           write_file("finder", since, "", token)
           exitStatus = subprocess.call("docker-compose -f github_finder/fig-custom.yml up",  shell=True)
        elif github == "single":
            project = askUser("Enter the full GitHub repository you wish to download(ie. museprogram/muse)\n")
            print("Running github crawler over single project: " + project)
            write_file("single", project, output, token)
            exitStatus = subprocess.call("docker-compose -f github_crawler/fig-custom.yml up",  shell=True)
        elif github == "search":
            query = askUser("Enter a search query from the GitHub api:\n")   
            print("Running github crawler over search query: " + query)            
            write_file("search", query, output, token)
            exitStatus = subprocess.call("docker-compose -f github_crawler/fig-custom.yml up",  shell=True)
        elif github == "file":
            if not filename:
                filename = askUser("Enter a filename containing GitHub repos in the form <author>/<repo>\n")   
            print("Running github crawler over file: " + filename)
            write_file("file", filename, output, token)
            exitStatus = subprocess.call("docker-compose -f github_crawler/fig-custom.yml up",  shell=True)
        elif github == "default":
            print("Running github crawler")
            write_file("default", "", output, token)
            exitStatus = subprocess.call("docker-compose -f github_crawler/fig-custom.yml up",  shell=True)
        else:
            parser.print_help()
            sys.exit(0)
                   
    if sourceforge:
        if not output:
           print ("No --out  folder was supplied for project downlaod")
           parser.print_help()
           sys.exit(1)
        if sourceforge == "default":
            if startID:
                    print("Running sourceforge crawler...")
                    sfCrawler.crawlSourceForge(startID, output, redisHost)
            else:
                    print("SourceForge startID is not valid: " + str(startID))
        else:
            parser.print_help()
            sys.exit(0)
else:
    parser.print_help()
    sys.exit(0)
