##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
#  Remove a list of projects from the ElasticSearch Mapping
#    it will remove project along with all commits and file mappings associated
from elasticsearch import Elasticsearch, helpers

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("index", help="elasticsearch index name")
parser.add_argument("filename", help="filename of project_ids to delete")
args = parser.parse_args()
index_name = args.index
file_name = args.filename

project_ids = open(file_name).read().split()

es = Elasticsearch()
parent_query =  {
              "ids" : {
              "values" : project_ids
              }
            }

child_query = {
                "has_parent" : {
                  "parent_type" : "project",
                  "query" : parent_query
                }
              }

counter=dict(project=0,commit=0,file=0)
for query in child_query, parent_query:
    res = helpers.scan(es, {"query": query}, index=index_name, fields=['_parent'])
    for hit in res:
        kwargs = dict(index=hit['_index'], doc_type=hit['_type'], id=hit['_id'])
        if 'fields' in hit:
            kwargs["parent"]=hit['fields']['_parent']
        es.delete(**kwargs)
        counter[hit["_type"]] += 1
        print ".",

print
for doc_type, count in counter.items():
  print count, doc_type, "records deleted"
