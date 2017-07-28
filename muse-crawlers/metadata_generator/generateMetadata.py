##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
'''
Generate the necessary MUSE metadata for any project repository given the required parameters; project name, description, date, url, etc.

this will generate the index.json and info.json for the specified project which is required metadata for proper indexing into ElasticSearch

Created on June 21, 2017
@author: nathan
'''
import argparse
import sys
import subprocess

import errno    
import os


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

# write out a info.json for the project given the specified params
def write_info(path, repo, pid, name, description, language, created_at, uid, url ):
    repo = repo.lower()
    infojson =  "{\"id\":\"" + pid + "\",\"html_url\":\"" + url + "\",\"full_name\":\"" + name.encode('ascii', 'ignore').decode('ascii') + "\",\"description\":\"" + description.encode('ascii', 'ignore').decode('ascii') + "\",\"language\":\"" + language + "\",\"created_at\":\"" + created_at + "\",\"uuid\":\"" + uid + "\"}"
  
    f = open(path + "/" + repo + "/" + 'info.json', 'w')
    f.write(infojson) # python will convert \n to os.linesep
    f.close() 


# write out a index.json for the project given the specified params
def write_index(path, repo, corpus_release, project_id, project_name, crawled_date, uuid ):
    site = repo
    repo = repo.lower()
    indexjson = "{\"corpus_release\":\"" + corpus_release + "\",\"code\":\"./latest\", \"site_specific_id\":\"" + project_id + "\",\"repo\":\"" + repo + "\",\"crawler_metadata\":[\"./" + repo + "/info.json\",\"./" + repo + "/languages.json\"],\"name\":\"" + project_name.encode('ascii', 'ignore').decode('ascii') + "\",\"site\":\"" + site + "\",\"crawled_date\":\"" + crawled_date + "\",\"uuid\":\"" + uuid + "\"}" 
 
    f = open(path + "/" + 'index.json', 'w')
    f.write(indexjson) 
    f.close() 

'''
class GenerateMetadata(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)
        
parser = GenerateMetadata(formatter_class=argparse.RawTextHelpFormatter, description='Generate MUSE metadata files necessaary for integration into the MUSE corpus.\n')
parser.add_argument("project_path", help="path of the project on disk to generate project metadata", action="store", nargs="?" )
parser.add_argument("repo", help="name of the repository these projects are from", action="store", nargs="?" )
parser.add_argument("corpus_release", help="floating point number to denote which release of the corpus these projects are (ie. 2.0)", action="store", nargs="?" )
parser.add_argument("projectID", help="the unique project id (given by repository)", action="store", nargs="?" )
parser.add_argument("uuid", help="unique uuid given to this projectt", action="store", nargs="?" )
parser.add_argument("projectName", help="name of the project", action="store", nargs="?" )
parser.add_argument("description", help="description of the project", action="store", nargs="?" )
parser.add_argument("language", help="language of the project", action="store", nargs="?" )
parser.add_argument("created_date", help="date project was created", action="store", nargs="?" )
parser.add_argument("crawled_date", help="date project was crawled", action="store", nargs="?" )
parser.add_argument("url", help="html url of the project", action="store", nargs="?" )

if len(sys.argv) == 1:
    parser.print_help()
    sys.exit(1)

args = parser.parse_args()
path = args.project_path
site = args.repo
repo = args.repo.lower()
corpus_release = args.corpus_release
pid = args.projectID
puuid = args.uuid
pname = args.projectName
pdate = args.created_date
cdate = args.crawled_date
pdesc = args.description
plang = args.language
purl = args.url

# create metadata folder in project
mkdir_p(path + "/" + repo)

# create necessaary MUSE metadata for integration (index.json, info.json)
write_index(path, repo, corpus_release, pid, pname, cdate, puuid)
write_info(path, repo, pid, pname, pdesc, plang, pdate, puuid, purl)
'''
