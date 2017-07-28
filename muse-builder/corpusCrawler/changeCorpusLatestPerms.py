#!/usr/bin/python
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
from __future__ import print_function

import copy
import datetime
import getopt
import json
import multiprocessing
import os
import os.path
import sys
import time
import traceback

from elasticsearch import Elasticsearch
from elasticsearch import helpers

from locallibs import debug
from locallibs import printMsg
from locallibs import warning

from redisHelper import RedisQueue

###################
### check to see if elasticsearch is running
# curl http://38.100.20.212:9200

### check elasticsearch index health status
# curl -XGET 'http://38.100.20.212:9200/_cluster/health?pretty=true'

### check node configuration
# curl -XGET 'http://localhost:9200/_nodes' | jq .

### check index size
#  curl 'localhost:9200/_cat/indices?v'

### index stats 
# curl http://38.100.20.212:9200/_stats?pretty=true

### get indexes & aliases
# curl http://38.100.20.212:9200/_aliases?pretty=true

### delete index
# curl -XDELETE 'http://38.100.20.212:9200/muse-corpus-source/?pretty=true'

#wildcard?
# curl -XDELETE 'http://38.100.20.212:9200/muse-corpus*/?pretty=true'

# should delete all indexes
### curl -XDELETE 'http://38.100.20.212:9200/_all/?pretty=true'

# curl -XDELETE 'http://38.100.20.212:9200/muse-corpus-source/?pretty=true'

### get all docs in index (up to 10)
# curl -s -XGET 'http://38.100.20.212:9200/muse-corpus-source/_search?pretty=true&q=*:*'

### get all docs in index (up to 10,000)
# curl -s -XGET 'http://38.100.20.212:9200/muse-corpus-source/_search?pretty=true&q=*:*&size=10000' | less

### count number of docs per index
# curl -XGET 'http://38.100.20.212:9200/muse-corpus-source/muse-project-files/_count'

### count number of docs per type in an index
# curl "38.100.20.212:9200/muse-corpus-source/_search?search_type=count" -d '{
#     "facets": {
#         "count_by_type": {
#             "terms": {
#                 "field": "_type"
#             }
#         }
#     }
# }'

###################

###
# consumer process that descends into each queued project path changing the permissions of all directories and files to ensure not write bits are set
###
def changePerms(tTup):

    (sProjectPath, dConfig) = tTup

    sLatestDir = os.path.join(sProjectPath, 'latest')

    if os.path.exists(sLatestDir):

        if os.path.isdir(sLatestDir):

            # project-path/latest exists as a directory

            if dConfig['debug']: debug('func: changePerms()', 'changing directory permissions on', sLatestDir)

            # change directory permissions to 555
            os.system('find ' + sLatestDir + ' -type d -exec chmod 555 \'{}\' \;')

            if dConfig['debug']: debug('func: changePerms()', 'changing file permissions on', sLatestDir)

            # change file permissions to 4444
            os.system('find ' + sLatestDir + ' -type f -exec chmod 444 \'{}\' \;')

        else:

            warning('func changePerms() latest exists but is not a directory under path:', sLatestDir)

    else:

        warning('func changePerms() latest does not exist under path:', sProjectPath, 'at', sLatestDir)


###
# consumer process that reads off redis queue and processes each project
###
def processProjects(dConfig):

    qRedis = RedisQueue(dConfig['redis-queue-name'], namespace='queue', host=dConfig['redis-loc'])

    while 1:

        # get next project to process
        sProjectPath = qRedis.get(block=True, timeout=30)

        if sProjectPath:

            changePerms( (sProjectPath, dConfig) )
            
        else:

            break
###
# producer process that populates redis queue with project path roots
###
def findProjects(sCorpusPath, iForks, dConfig):

    lProjectPaths = []

    if dConfig['redis']:

        qRedis = RedisQueue(dConfig['redis-queue-name'], namespace='queue', host=dConfig['redis-loc'])

        # ensure redis queue is empty prior to starting consumers
        qRedis.flush()

    iCount = 0

    for sRoot, lDirs, lFiles in os.walk(sCorpusPath):

        iLevel = sRoot.count(os.sep)

        if iLevel >= 11:

            del lDirs[:]

        if iLevel == 11:

            if dConfig['debug']: debug('func: findProjects()', 'projects-root:', sRoot, iLevel)

            if dConfig['redis']:
            
                qRedis.put(sRoot)
            
            else:

                lProjectPaths.append(sRoot)
            
            iCount += 1

            if dConfig['debug'] and iCount >= 1: break

    printMsg('func: findProjects()', str(iCount), 'projects loaded into queue for processing')

    return lProjectPaths

###
def usage():
    warning('Usage: changeCorpusLatestPerms.py --corpus-dir-path=/data/corpus --forks=5 --redis --debug')
    warning('Usage: Please note that above directory arguments are defaults if not supplied and both directories must exist on the filesystem.')
    warning('Usage: if mode is supplied, it must be either set to thread or process. thread is the default.')

###
def main(argv):

    # defaults
    sCorpusPath = '/data/corpus'

    dConfig = {}
    dConfig['debug'] = False
    dConfig['redis-queue-name'] = 'muse-project-paths-perms'
    dConfig['redis-loc'] = '38.100.20.212'
    dConfig['redis'] = False

    dConfig['time-stamp'] = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S')

    iForks = 10
    bError = False

    ### command line argument handling
    options, remainder = getopt.getopt(sys.argv[1:], 'c:f:rd', ['corpus-dir-path=','forks=','redis','debug'])

    # debug('func: main()', 'options:', options)
    # debug('func: main()', 'remainder:', remainder)

    for opt, arg in options:
    
        if opt in ('-c', '--corpus-dir-path'):

            sCorpusPath = arg

        elif opt in ('-d', '--debug'):

            dConfig['debug'] = True

        elif opt in ('-r', '--redis'):

            dConfig['redis'] = True

        elif opt in ('-f', '--forks'):

            try:
            
                iForks = int(arg)

            except ValueError as e:

                bError = True

    if not os.path.isdir(sCorpusPath):

        bError = True

    if bError: usage()
    else:

        iStart = time.time()

        ### setup producer

        lProjectPaths = []

        if dConfig['redis']:

            # call producer process that populates redis queue with project path roots
            
            pProducer = multiprocessing.Process( target=findProjects, args=(sCorpusPath, iForks, dConfig) )
            pProducer.start()

        else:
        
            lProjectPaths = findProjects(sCorpusPath, iForks, dConfig)

        ### setup consumers
        lArgs = []

        # create pool of workers
        oPool = multiprocessing.Pool(processes=iForks)

        if dConfig['redis']: 

            for i in range(0, iForks):

                lArgs.append(dConfig)

            ### do work -- use pool of workers to descend into each project path recording/ingesting all file names
            oPool.map(processProjects, lArgs)
            pProducer.join()

        else:

            for sPath in lProjectPaths:

                lArgs.append( (sPath, dConfig) )

            ### do work -- use pool of workers to descend into each project path recording/ingesting all file names
            oPool.map(findProjectFiles, lArgs)

        oPool.close()
        oPool.join()

        if dConfig['debug']: debug('func: main()', "all processes completed") 

        iEnd = time.time()

        printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
