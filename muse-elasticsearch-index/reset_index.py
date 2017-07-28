#!/usr/bin/python
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
import time
import json
from elasticsearch import Elasticsearch

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("index", help="elasticsearch index name")
parser.add_argument("-o", "--overwrite", help="overwrite index if exists",
                    action="store_true")
args = parser.parse_args()
index_name = args.index

es = Elasticsearch()
if args.index in es.indices.get(index='*').keys() and not args.overwrite:
    print args.index, "exists.  Must use overwrite option"
    exit()
print "Resetting", args.index

custom_analyzer = {
  "index": {
    "analysis": {
      "analyzer": {
        "custom_lower": {
          "type": "custom",
          "tokenizer": "keyword",
          "filter": [
            "lowercase"
          ]
        }
      }
    }
  }
}

def reset_index(index_name):
    mapping = json.load(open("brian_mapping.json", "rb"))
    # custom_analyzer=json.load(open("custom_analzyer.json", "rb"))
    es.indices.delete(index=index_name, ignore=404)
    es.indices.create(index=index_name)
    time.sleep(1)
    es.indices.close(index=index_name)
    time.sleep(1)
    es.indices.put_settings(index=index_name, body=custom_analyzer)
    time.sleep(1)
    es.indices.open(index=index_name)
    time.sleep(1)
    es.indices.put_mapping(index=index_name, doc_type="project", body={"project": mapping["project"]})
    es.indices.put_mapping(index=index_name, doc_type="commit", body={"commit": mapping["commit"]})
    es.indices.put_mapping(index=index_name, doc_type="file", body={"file": mapping["file"]})
    print "INDEX RESET"

reset_index(args.index)
