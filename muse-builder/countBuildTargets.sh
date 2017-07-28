#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

#count where Makefile appears:

#curl -s -XGET 'http://38.100.20.212:9200/muse-corpus-source/_count?q=file:Makefile'

curl -XGET 'http://38.100.20.210:9200/muse-corpus-source/_count?pretty' -d '{
 "query": {
    "bool": {
      "must": [
        {
          "match": {
            "file.raw": "configure.ac"
          }
        },
        {
          "match": {
            "path.analyzed": "latest/*"
          }
        }
      ]
    }
  }
}'

curl -XGET 'http://38.100.20.210:9200/muse-corpus-source/_count?pretty' -d '{
 "query": {
    "bool": {
      "must": [
        {
          "match": {
            "file.raw": "configure.in"
          }
        },
        {
          "match": {
            "path.analyzed": "latest/*"
          }
        }
      ]
    }
  }
}'

curl -XGET 'http://38.100.20.210:9200/muse-corpus-source/_count?pretty' -d '{
 "query": {
    "bool": {
      "must": [
        {
          "match": {
            "file.raw": "CMakeLists.txt"
          }
        },
        {
          "match": {
            "path.analyzed": "latest/*"
          }
        }
      ]
    }
  }
}'