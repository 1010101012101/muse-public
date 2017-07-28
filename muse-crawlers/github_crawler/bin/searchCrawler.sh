#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# Directed Downloads given a search query
# Given a specific Github query for specific projects, download only these projects 
# phase 2 general downlaod:  /data/corpus_8tof/directedGithubPH2


node ./js/SearchGithub.js --token c65563aedd99f1e0efe410516e199eb28536b0f4 --mongodb mongodb://$DB_1_PORT_27017_TCP_ADDR:$DB_1_PORT_27017_TCP_PORT/github --collection github_2014OCT27 --redis_server $REDIS_1_PORT_6379_TCP_ADDR --redis_db 3 --out /data/crawler_SAN/RAT  --query "\"backdoor\"+in:description+language:C%2B%2B+language:C+language:Java" 
