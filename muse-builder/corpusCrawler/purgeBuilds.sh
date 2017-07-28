#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# delete log files
find /data/crawl -type f -exec rm '{}' \;

tree /data/crawl

# truncate build status table in mysql
python createNewBuildStatusTable.py

# clean up elasticsearch build index
curl -XDELETE 'http://localhost:9200/muse-corpus-build/?pretty=true' && curl 'localhost:9200/_cat/indices?v'

# delete build tar balls
rm -rf /nfsbuild/nfsbuild/*

tree /nfsbuild/nfsbuild