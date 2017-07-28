#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# TO DOWNLOAD A SPECIFIC PROJECT FROM GITHUB (single)

#nodejs ./js/SearchGithub.js --token c65563aedd99f1e0efe410516e199eb28536b0f4 --mongodb mongodb://localhost:27017/github --collection github_test --redis_server localhost --redis_db 4 --out /data/test --query "android+in:name,description,readme+stars:>4+language:Java+size:<102400+created:2011-09-01..2011-10-01" 

node ./js/gitdownload.js --token c65563aedd99f1e0efe410516e199eb28536b0f4 --project "apache/commons-math" --mongodb mongodb://$DB_1_PORT_27017_TCP_ADDR:$DB_1_PORT_27017_TCP_PORT/github --collection github_sri --redis_server $REDIS_1_PORT_6379_TCP_ADDR --redis_db 4 --out /data/sri  
