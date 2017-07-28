#!/usr/bin/python
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
import os
import json
import pprint
import time
from collections import defaultdict, Counter
from elasticsearch import Elasticsearch

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("index", help="elasticsearch index name")
parser.add_argument("dir_list", help="filename containing list of project dirs")
parser.add_argument("-np", "--noproject", help="Do not index projects records",
                    action="store_true")
parser.add_argument("-nf", "--nofile", help="Do not index file records",
                    action="store_true")
parser.add_argument("-nc", "--nocommit", help="Do not index commit records",
                    action="store_true")
parser.add_argument("-x", "--x_of", help="parallel script this is (0 indexed)",
                    type=int, default=0)
parser.add_argument("-y", "--of_y", help="Scripts you intend to run in parallel", type=int, default=1)
args = parser.parse_args()
index_name = args.index
f_name = args.dir_list
if args.noproject:
    print "NOT indexing project records"
if args.nofile:
    print "NOT indexing file records"
if args.nocommit:
    print "NOT indexing commit records"

x_of = args.x_of
of_y = args.of_y
if x_of < 0 or x_of >= of_y:
    print "Invalid x_of.  Parallel scripts are referenced 0 to of_y - 1"
    exit()
print "This is script {} of {}".format(x_of, of_y)


#The following variable are pulled from the command line
#index_name = "briandevjune4"
#f_name = "20150615AllProjects.csv"

#build_base = '/nfsbuild/'
debug = False

es = Elasticsearch()
pp = pprint.PrettyPrinter(indent=2)

def parse_location(full_path):
    filename = full_path.rpartition('/')[2]
    extension = filename.rpartition('.')[2]
    return {"file_extension": extension,
            "file_name": filename,
            "full_path": full_path
           }

def repr_bounded_value(record, key, max_length=1024):
    return repr(record.get(key,""))[:max_length]


class Project:
    dispatch = {}
    if args.nofile and args.nocommit:
        print "using slim dispatch"
        dispatch = {"languages.json":"extract_language",
                "info.json":"extract_info",
                "topics.json":"extract_topic",
                "filter.json":"extract_filter",
                "totalSize.json":"extract_size",
                "sloc.json":"extract_sloc",
                "index.json":"extract_index"}
    else:
        dispatch = {"languages.json":"extract_language",
                "comments.json":"extract_comments",
                "info.json":"extract_info",
                "topics.json":"extract_topic",
                "commits.json":"extract_commits",
                "doxygen.json":"extract_doxygen",
                "filter.json":"extract_filter",
                "totalSize.json":"extract_size",
                "sloc.json":"extract_sloc",
                "index.json":"extract_index"} #,
    #            "build.json":"extract_build"}
    sw_dispatch = {"Readme":"extract_readme",
                   "README":"extract_readme",
                   "INSTALL":"extract_install"}

    def __init__(self, root_path, uuid):
        self.root_path = root_path
        self.uuid = uuid
        self.root_len = len(root_path)
        self.record = {"uuid": uuid, "project":{}, "commit":{}, "file":defaultdict(dict)}

   # def extract_build(self, contents):
   #     print contents.keys()
   #     self.record["project"]["buildStatus"] = contents.get("buildStatus", "")

    def extract_info(self, contents):
        self.record["project"]["description"] = contents.get("description", "")
        self.record["project"]["name"] = contents.get("name", "")
        self.record["project"]["html_url"] = contents.get("html_url", "")
        self.record["project"]["full_name"] = contents.get("full_name", "")
        self.record["project"]["languageMain"] = contents.get("languageMain", "")
        created_at = contents.get("created_at")
        if created_at == "null":
            created_at = None
        self.record["project"]["created_at"] = created_at

    def extract_index(self, contents):
        self.record["project"]["site"] = contents.get("site","")
        self.record["project"]["corpus_release"] = contents.get("corpus_release","")
        crawled_date = contents.get("crawled_date")
        if crawled_date == "null":
            crawled_date = None
        self.record["project"]["crawled_date"] = crawled_date

    def extract_language(self, contents):
        self.record["project"]["language"] = contents.keys()
        sum = 0
        for value in  contents.values():
            sum = sum + value
        self.record["project"]["src_size"] = sum

    def extract_topic(self, contents):
        self.record["project"]["topic"] = contents.keys()

    def extract_size(self, contents):
        self.record["project"]["total_size"] = contents.get("total_size")

    def extract_sloc(self, contents):
        self.record["project"]["sloc"] = contents["results"]["languages"]["total"].get("@code")
        self.record["project"]["cloc"] = contents["results"]["languages"]["total"].get("@comment")
        self.record["project"]["num_files"] = contents["results"]["languages"]["total"].get("@sum_files")

    def extract_rel_location(self, item):
        rel_location = item["location"]["@file"][self.root_len+1:]
        self.record["file"][rel_location].update(parse_location(rel_location))
        return rel_location

    def extract_filter(self, contents):
        #if "buildStatus" in self.record["project"]:
            #del contents["buildStatus"]
        self.record["project"].update(contents)

    def extract_readme(self, contents):
        if "readme" in self.record["project"]:
            self.record["project"]["readme"].append(contents)
        else:
            self.record["project"]["readme"] = [contents,]

    def extract_install(self, contents):
        if "install" in self.record["project"]:
            self.record["project"]["install"].append(contents)
        else:
            self.record["project"]["install"] = [contents,]

    def extract_doxygen(self, contents):
        for item in contents["doxygen"].get("compounddef",()):
            item_kind = item["@kind"]
            if item["@kind"] == "interface":
                try:
                    inherited = [value["label"] for value in item["inheritancegraph"]["node"]]
                except:
                    continue
                rel_location = self.extract_rel_location(item)
                self.record["file"][rel_location]["class_inherited"] = inherited
            elif item["@kind"] == "file":
                var_list = []
                func_list = []
                try:
                    sectiondef = item["sectiondef"]
                except KeyError:
                    continue
                rel_location = self.extract_rel_location(item)
                if type(sectiondef) is dict:
                    sectiondef = [sectiondef,]
                for file_item in sectiondef:
                    kind = file_item["@kind"]
                    memberdefs = file_item.get("memberdef",[])
                    if type(memberdefs) is dict:
                        memberdefs = [memberdefs,]
                    if kind == "func":
                        for memberdef in memberdefs:
                            params = memberdef.get("param", ())
                            if type(params) is dict:
                                params = [params,]
                            member_func = {"name": memberdef.get("name",""),
                                           "return_type": repr_bounded_value(memberdef, "type"),
                                           "parameter_type": [repr_bounded_value(param, "type") for param in params]
                                          }
                            func_list.append(member_func)
                    elif kind == "var":
                         for memberdef in memberdefs:
                             member_var = {"name": memberdef["name"],
                                           "type": repr_bounded_value(memberdef, "type")
                                          }
                             var_list.append(member_var)
                self.record["file"][rel_location]["variable"] = var_list
                self.record["file"][rel_location]["function"] = func_list

    def extract_commits(self, contents):
        commits = []
        sha_lookup = defaultdict(list)
        for commit in contents:
            sha = commit["sha"]
            for parent in commit["parents"]:
                sha_lookup[parent["sha"]].append(sha)
        for commit in contents:
            sha = commit["sha"]
            message = commit["commit"]["message"]
            parents = [parent["sha"] for parent in commit["parents"]]
            children = sha_lookup.get(sha)
            commits.append({"id":sha, "parent_id": parents, "child_id": children, "message":message})
        self.record["commit"] = commits

    def extract_comments(self, contents):
        if not contents:
            return
        for item in contents["comment_data"]:
            filename = item["file"]
#            pp.pprint(item)
            comments = [record["string"].strip() for record in item["strings"]]
            self.record["file"][filename]["comment"] = comments
            self.record["file"][filename].update(parse_location(filename))

    def process_dir(self): #, uuid, root_dir):
        #build_path = build_base + '{}/{}/{}/{}/{}/{}/{}/{}/'.format(*self.uuid[:8])
        #try:
        #    build_path = build_path+"{}/build.json".format(self.uuid)
        #    contents = json.load(open(build_path, "rb"))
        #    self.extract_build(contents)
        #except:
        #    pass
        #for root, dirs, files in os.walk(self.root_path):
        for root, dirs, files in walklevel(self.root_path, 2):
            for filename in files:
                if filename in self.dispatch:
                    if debug:
                        print root, filename
                    try:
                        contents = open(os.path.join(root, filename), "rb").read()
                    except TabError: #IOError:
                        if debug:
                            print "Bad File:", os.path.join(root, filename)
                        continue
                    if not contents:
                        if debug:
                            print "Empty:", os.path.join(root, filename)
                        continue
                    try:
                        json_contents = json.loads(contents)
                    except ValueError:
                        fixed_contents = contents.replace("]\n[", ",").replace("][", ",").replace(",]", "]")
                        if debug:
                            print "Bad JSON:", os.path.join(root, filename)
                        json_contents = json.loads(fixed_contents)
                    getattr(self, self.dispatch[filename])(json_contents)
                else:
                    for file_start, file_func in self.sw_dispatch.items():
                        if filename.startswith(file_start):
                            try:
                                contents = open(os.path.join(root, filename), "rb").read().decode("utf8", errors='ignore')
                            except:
                                print "Bad filename:", root, filename
                                continue
                            getattr(self, file_func)(contents)

        self.record["file"] = dict(self.record["file"])

def walklevel(some_dir, level=1):
    some_dir = some_dir.rstrip(os.path.sep)
    assert os.path.isdir(some_dir)
    num_sep = some_dir.count(os.path.sep)
    for root, dirs, files in os.walk(some_dir):
        yield root, dirs, files
        num_sep_this = root.count(os.path.sep)
        if num_sep + level <= num_sep_this:
            del dirs[:]

def index_project(record):
    uuid = record["uuid"]
    print ".",
    if not args.noproject:
        es.index(index=index_name, doc_type="project", body=record["project"], id=uuid, timeout=30)
    if not args.nofile:
        for file_record in record["file"]:
            _id = uuid + file_record["full_path"]
            es.index(index=index_name, doc_type="file", body=file_record, id=_id, parent=uuid, timeout=30)
    if not args.nocommit:
        for commit_record in record["commit"]:
            _id = uuid + commit_record["id"]
            es.index(index=index_name, doc_type="commit", body=commit_record, id=_id, parent=uuid, timeout=30)

f_projects = open(f_name)
projects = [line.strip().split(",") for line in f_projects if line.strip()]

#Load list of already indexed documents
try:
    already_analyzed = set(open(index_name+"_{}_of_{}_success.log".format(x_of, of_y), "rb").read().split())
except:
    already_analyzed = set()

#Append to list of already indexed projects,
f_good = open(index_name+"_{}_of_{}_success.log".format(x_of, of_y), "ab")
#Overwrite the list of bad projects.  These are retried each time
f_bad = open(index_name+"_{}_of_{}_failed.log".format(x_of, of_y), "wb")

#Iterate through list of projects
count = 0
skip_count = 0
start_time = time.time()
for root, dir_name in projects:
    if hash(dir_name) % of_y != x_of:
        continue
    if len(root.split('/')) != 11:
        print "Skipping:", root
        continue
    if dir_name in already_analyzed:
        skip_count +=1
        if skip_count % 100 == 0:
            print "Skip:", skip_count
        continue
    if len(dir_name) == 36 and len(dir_name.split('-')) == 5:
        project = Project(os.path.join(root, dir_name), dir_name)
        count +=1
        if count % 10 == 0:
            print count, 3600 * count / (time.time() - start_time), "projects/hour"
        if count < 0:
            continue
        try:
            project.process_dir() #dir_name, root)
        except (KeyboardInterrupt, SystemExit):
            raise
        except: #TabError:
            f_bad.write(dir_name+"\n")
            f_bad.flush()
            continue
        project.record["file"] = project.record["file"].values()
        #as_json = json.dumps(project.record, indent=2, sort_keys=True)
        # continue
        try:
            index_project(project.record)
        except (KeyboardInterrupt, SystemExit):
            raise
        except: #TabError:
            f_bad.write(dir_name+"\n")
            f_bad.flush()
            continue
        f_good.write(dir_name+"\n")
        f_good.flush()

