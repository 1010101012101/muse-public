#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# stop straggling proesses

ps a | grep buildProjectsByType

for processId in `ps a | grep buildProjectsByType | cut -d " " -f 1`; do echo $processId; kill $processId; done

ps a | grep buildProjectsByType

# remove log files
find /data/crawl/ -type f -exec rm -f '{}' \;

tree /data/crawl

# stop containers
for conID in `docker ps -a | grep musebuilder | cut -d " " -f 1`; do docker stop $conID; sleep 2; done

docker ps -a

# remove containers
for conID in `docker ps -a | grep musebuilder | cut -d " " -f 1`; do docker rm $conID; sleep 2; done

docker ps -a

# delete container volumes / directories
find /data/builder -maxdepth 1 -type d -name "muse*" -exec rm -rf '{}' \;

# rm -rf /nfsbuild/nfsbuild/*

# es
# curl -XDELETE 'http://localhost:9200/muse-corpus-build/?pretty=true' && curl 'localhost:9200/_cat/indices?v'
# curl 'localhost:9200/_cat/indices?v'

# mysql
# truncate buildStatus;
# select * from buildStatus;

