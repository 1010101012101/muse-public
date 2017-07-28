##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
from bs4 import BeautifulSoup
from datetime import datetime
import sys 
sys.path.insert(0, '../')
from metadata_generator import generateMetadata

#import pysvn
import requests
import uuid
try:
    # For Python 3.0 and later
    from urllib.request import urlretrieve
except ImportError:
    # Fall back to Python 2's urllib2
    from urllib import urlretrieve 
import os
import errno 
import redis
import json
import argparse 
import subprocess 
import magic

def is_json(myjson):
  try:
    json_object = json.loads(myjson)
  except ValueError:
    return False
  return True

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

# Crawl SourceForge repo given a starting project id
#   i - starting projectID of SF project
#   out - output folder to store crawled projects
def crawlSourceForge(i, out, redisHost):

  redisDB = 9
  repo = "sourceforge"
  site = "SourceForge"
  tmp = "tmp/"
  mkdir_p(tmp)
  while True:

    print ("Working on SF project id: " + str(i)) 

    # Use Redis to determine if we have already downloaded
    bExists = None 
    redisc = redis.StrictRedis(host=redisHost, port=6379, db=redisDB)
    uid = redisc.get('id-to-uuid:sourceforge:' + str(i))
    if uid is not None:
        bExists = True
        i = i + 1;
        print ("   already exists, skipping project")
        print ("")
        continue

    hasSrc = None
    urlStr = "http://sourceforge.net/project/showfiles.php?group_id=" + str(i)
    r  = requests.get(urlStr)
    data = r.text

    soup = BeautifulSoup(data, "html.parser")
    for link in soup.find_all('a'):
        currlink = link.get('href')
        if currlink is None:
            continue        

        # if latest source exists to download
        if 'source=files' in currlink:
            hasSrc = True
                
            # grab project name from link
            project = currlink.split("/")
            projectname = project[2]
            print ("   Project name: " + projectname)
            archive = tmp + projectname + ".tar.bz2"

            '''
            # Subversion client not working for many projects
            svnclient = pysvn.Client()
            svnclient.exception_style = 0
            try:
                rev = svnclient.checkout("https://svn.code.sf.net/p/" + projectname + "/code/trunk", latest)
            except pysvn.ClientError, e:
                print str(e)
                continue
            '''

            strUnpack = None
            urlretrieve("https://sourceforge.net/" + currlink, filename= archive)
            filetype = magic.from_file(archive)
            print ("   filetype: " + filetype)
            compression = filetype.split(" ")[0]
            print ("   Detected source archive format:  *** " +  compression + " ***")
            # determine file archive format and unpack src code
            if compression == "gzip":
                #print ( "  tar xzf " + archive + " -C " + latest)
                strUnpack = "tar xzf " + archive + " -C "
            elif compression == "bzip2":
                #print ("  tar jxf " + archive + "-C ")
                strUnpack = "tar jxf " + archive + " -C "
            elif compression == "Zip" :
                #print ("  unzip -qq -o " + archive + " -d " + latest)
                strUnpack = "unzip -qq -o " + archive + " -d "
            elif compression == "Java":
                #print ("  unzip -qq -o " + archive + " -d " + latest)
                strUnpack = "unzip -qq -o " + archive + " -d "
            elif compression == "RAR":
                #print ("  unrar x -o+ -inul " + archive + " " + latest)
                strUnpack = "unrar x -o+ -inul " + archive + " "
            elif compression == "7-zip":
                #print ( "7za x " + archive +" -o" + latest)
                strUnpack = "7za x " + archive +" -o"
            else:
                print ("   unable to UNPACK; skipping project...")
                continue   

            # if redis key doesnt exist create one
            if bExists is None:
                uid =  str(uuid.uuid4().hex)
                redisc.set('uuid-to-id:sourceforge:' + uid, str(i))
                redisc.set('id-to-uuid:sourceforge:' + str(i), uid)
            uidpath = uid[0] + "/" + uid[1] + "/" +  uid[2] + "/" + uid[3] + "/" + uid[4] + "/" + uid[5] + "/" + uid[6] + "/" + uid[7] + "/" + uid + "/"
            output_path = out + uidpath
            print ("   UUID:  " + uid)
            print ("   Downloading to: " + output_path)

            # make source directory 
            latest = output_path + "latest"
            mkdir_p(latest)
             
            # Unpack source code
            exitStatus = subprocess.call( strUnpack + latest, shell=True)
            if ( exitStatus > 0 ):
                print ( "   error unpacking archive, skipping project")
                continue
   
            # Remove archive file after unpacking
            subprocess.call( "rm -fr " + archive, shell=True)

	    # create project metadata folder              
            metadata_folder = output_path + "/" + repo + "/"
            mkdir_p(metadata_folder)

            # generate metadata for project
            print ("   generating metadata...")
            url_metadata =  "https://sourceforge.net/rest/p/" + projectname
            metadata = requests.get(url_metadata)

            if is_json(metadata.text) is True:
                mjson = json.loads(metadata.text)
                name = mjson["name"]
                sname = mjson["shortname"]
                desc =  mjson["short_description"].replace('\n', ' ').replace('\r', ' ').replace('\t', ' ').replace('\\', '/').replace('"', "")
                date = mjson["creation_date"] + "T12:00:00Z"
                url = mjson["url"]
                crawl_date = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')

                generateMetadata.write_index(output_path, site, "3.0", str(i), name, crawl_date, uid)
                generateMetadata.write_info(output_path, site, str(i), name, desc, "null", date, uid, url)

                '''
                language=$(jq -r .categories.language[0].fullname $project/metadata.json)
                os=$(jq -r .categories.os[0].fullname $project/metadata.json)
                license=$(jq -r .categories.license[0].shortname $project/metadata.json)
                '''

            # bugs.json (check to see if project has one)
            url_bugs =  "https://sourceforge.net/rest/p/" + projectname + "/bugs"
            bugs = requests.get(url_bugs)
            if is_json(bugs.text) is True:
               print ("   downloading bugs...")
               bugs_file = open(metadata_folder + 'bugs.json', 'w')
               bugs_file.write(bugs.text.encode('ascii', 'ignore').decode('ascii'))
               bugs_file.close()

            # summary.json (check to see if project has one)
            url_summary =  "https://sourceforge.net/rest/p/" + projectname + "/summary"
            summary = requests.get(url_summary)
            if is_json(summary.text) is True:
               print ("   downloading summary...")
               summary_file = open(metadata_folder + 'summary.json', 'w')
               summary_file.write(summary.text.code('ascii', 'ignore').decode('ascii'))
               summary_file.close()

            # try to do something with commit url
            url_commits = "https://sourceforge.net/p/" + projectname + "/code/HEAD/tree"
            commits  = requests.get(url_commits)
#            y_file = open(metadata_folder + 'commits.html', 'w')
#            y_file.write(commits.text.encode('ascii', 'ignore').decode('ascii'))
#            y_file.close()
             
    i = i + 1;
    if hasSrc is None:
        print ("--- No source to download ---")
    print ("")


if __name__ == "__main__":
        class SFcrawler(argparse.ArgumentParser):
                def error(self, message):
                        sys.stderr.write('error: %s\n' % message)
                        self.print_help()
                        sys.exit(2)

        #mb startID CMD argument added for at which ID to start crawling and --output folder where projects will be saved
        parser = SFcrawler(formatter_class=argparse.RawTextHelpFormatter, description='Crawl SourceForge repository and download all Java, C++, and C projects.\n')
        parser.add_argument("startID", help="the sourceforge project id to start crawling from", type=int, action="store", nargs="?"  )
        parser.add_argument("--out", help="specify which folder to download projects to (required)", metavar="path", required=True, action="store", nargs="?" )
        parser.add_argument("--redis", help="specify which host redis is installed(defaults to localhost)", metavar="path", action="store", nargs="?", default="127.0.0.1" )
        args = parser.parse_args()
        startID = args.startID
        out = args.out
        redis = args.redis

        if len(sys.argv) == 1:
            parser.print_help()
            sys.exit(1)

        crawlSourceForge(startID, out, redis)

