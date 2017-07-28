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

import datetime
import getopt
import json
import multiprocessing
import os
import os.path
import sys
import time
import traceback
import Queue

from elasticsearch import Elasticsearch
from elasticsearch import helpers

from locallibs import debug
from locallibs import printMsg
from locallibs import warning

from redisQueue import RedisQueue

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
# consumer process that descends into each queued project path recording/ingesting all file names in that project
###
def findProjectFiles(dConfig):

    qRedis = RedisQueue(dConfig['redis-queue-name'], namespace='queue', host=dConfig['redis-loc'])
    oES = Elasticsearch(dConfig['es-instance-locs'])

    lIgnoreDirs = ['.git','.svn']

    dProject = {}
    dSource = {}

    dProject['_index'] = dConfig['es-index-name']
    dProject['_type'] = dConfig['es-index-type']

    dSource['crawl-time'] = dConfig['time-stamp']

    dSource['project-path'] = qRedis.get(block=True)

    lProjectFiles = []

    # if project path is '**done**', then break
    while dSource['project-path'] != '**done**':

        dSource['project-name'] = os.path.basename(dSource['project-path'])
        
        if dConfig['debug']: debug('func: findProjectFiles()', 'project-path:', dSource['project-path'], dSource['project-name'])

        for sRoot, lDirs, lFiles in os.walk(dSource['project-path']):

            if len(lProjectFiles) > dConfig['es-bulk-chunk-size']:

                # ingest chunk into elasticsearch
                helpers.bulk(oES, lProjectFiles)

                if dConfig['debug']: debug('func: findProjectFiles()', str( len(lProjectFiles) ), 'files loaded into elasticsearch')

                lProjectFiles = []

            for sFile in lFiles:

                sFilePath = os.path.join(sRoot, sFile)

                sRelPath = os.path.relpath(sFilePath, dSource['project-path'])

                dFile = { }

                try:

                    sRelPath.decode('utf-8')

                except (ValueError, UnicodeDecodeError) as e:

                    try:

                        sRelPath.decode('latin-1')

                    except (ValueError, UnicodeDecodeError) as e:

                        try:

                            sRelPath.decode('utf-16')

                        except (ValueError, UnicodeDecodeError) as e:

                            warning('func findProjectFiles():', 'sProjectPath:', dSource['project-path'], 'sProjectName:', dSource['project-name'], 'sFile:', sFile, 'sRelPath:', sRelPath, 'utf-8, latin-1, and utf-16 decoding failed', 'exception:', e)

                        else:

                            dSource['file'] = sFile.decode('utf-16')
                            dSource['path'] = sRelPath.decode('utf-16')
                            dProject['_source'] = dSource
 
                            lProjectFiles.append( dProject )

                    else:

                        dSource['file'] = sFile.decode('latin-1')
                        dSource['path'] = sRelPath.decode('latin-1')
                        dProject['_source'] = dSource

                        lProjectFiles.append( dProject )
          
                else:

                    dSource['file'] = sFile
                    dSource['path'] = sRelPath
                    dProject['_source'] = dSource

                    lProjectFiles.append( dProject )

            lDirs[:] = [ sDir for sDir in lDirs if sDir not in lIgnoreDirs ]
        
        # get next project to process
        dSource['project-path'] = qRedis.get(block=True)
    
    # index any remaining projects        
    if len(lProjectFiles) > 0:

        # ingest chunk into elasticsearch
        helpers.bulk(oES, lProjectFiles)

        if dConfig['debug']: debug('func: findProjectFiles()', str( len(lProjectFiles) ), 'files loaded into elasticsearch')
            
###
# producer process; finds specific build files from pre-existing elasticsearch index
###
def findBuildFiles(tTup):

    # unpack inputs from input tuple
    (sSearchString, dConfig) = tTup

    dConfig['redis-queue-name'] = dConfig['redis-queue-name'] % sSearchString

    if dConfig['debug']: debug('func: findBuildFiles() dConfig[\'redis-queue-name\']:', dConfig['redis-queue-name'])

    qRedis = RedisQueue(dConfig['redis-queue-name'], namespace='queue', host=dConfig['redis-loc'])
    
    # ensure redis queue is empty prior to starting consumers
    qRedis.flush()

    # setup elasticsearch client
    oES = Elasticsearch(dConfig['es-instance-locs'])

    #sQuery = { "query" : "file:" + sSearchString + "&lowercase_expanded_terms=false" }

    dQuery = {}
    dQuery['query'] = {}
    dQuery['query']['query_string'] = {}
    dQuery['query']['query_string']['fields'] = ['file.raw']
    # dQuery['query']['query_string']['fields'] = ['file.analyzed']
    dQuery['query']['query_string']['query'] = sSearchString
    dQuery['query']['query_string']['lowercase_expanded_terms'] = False

    if dConfig['debug']: debug( 'func: findBuildFiles() dQuery:', json.dumps(dQuery) ) 


    ''' ### working 10 document fetch
    dResponse = oES.search( index=dConfig['es-file-index-name'], doc_type=dConfig['es-file-index-type'], body=json.dumps(dQuery) )

    if dConfig['debug']: 

        for sHit in dResponse['hits']['hits']:
          debug('func: findBuildFiles() sHit: ', sHit)

    '''

    # scroll time set to 10 minutes, change as needed -- required for consistent results, the scroll token expires at the end of scroll time
    sScrollTime = "10m"
    dResponse = oES.search(index=dConfig['es-file-index-name'], doc_type=dConfig['es-file-index-type'], body=json.dumps(dQuery), search_type="scan", scroll=sScrollTime)
    sScrollId = dResponse['_scroll_id']

    if dConfig['debug']: debug('func: findBuildFiles() (after initial search) dResponse: ', dResponse)

    if dConfig['debug']: debug('func: findBuildFiles() search hits: ', dResponse['hits']['total'])


    #while not dResponse['timed_out'] and dResponse['hits']['hits']['total'] > 0:
    while not dResponse['timed_out'] and dResponse['hits']['total'] > 0:

        dResponse = oES.scroll(scroll_id=sScrollId, scroll=sScrollTime)

        sScrollId = dResponse['_scroll_id']
        
        #if dConfig['debug']: debug('func: findBuildFiles() dResponse: ', dResponse)

        if len(dResponse['hits']['hits']) > 0:

            for sHit in dResponse['hits']['hits']:
              if dConfig['debug']: debug('func: findBuildFiles() sHit: ', sHit)

        else:

            break

    # for i in range(0, dConfig['forks']):

    #     qRedis.put('**done**')

###
def usage():
    warning('Usage: labelProjectsByBuildType.py --forks=5 --debug')

###
def main(argv):

    dConfig = {}
    dConfig['es-bulk-chunk-size'] = 500
    dConfig['debug'] = False
    dConfig['forks'] = 5
    # binding to muse2 doesn't work right now
    dConfig['es-instance-locs'] = ['38.100.20.211','38.100.20.212']
    #dConfig['es-instance-locs'] = ['38.100.20.212']
    
    dConfig['es-file-index-name'] = 'muse-corpus-source'
    dConfig['es-file-index-type'] = 'muse-project-files'

    dConfig['es-project-index-name'] = 'muse-corpus-projects'
    dConfig['es-project-index-type'] = 'muse-project-buildtype'

    dConfig['redis-queue-name'] = 'muse-%s-projects'
    dConfig['redis-loc'] = '38.100.20.212'

    dConfig['time-stamp'] = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
    dConfig['version'] = '1.0'


    # sSearchStrings = ['configure','configure.ac','configure.in','Makefile','build.xml','pom.xml']
    # sSearchStrings = ['configure']
    sSearchStrings = ['configure','configure.ac','configure.in']

    bError = False

    ### command line argument handling
    options, remainder = getopt.getopt(sys.argv[1:], 'c:f:d', ['corpus-dir-path=','forks=','debug'])

    # debug('func: main()', 'options:', options)
    # debug('func: main()', 'remainder:', remainder)

    for opt, arg in options:

        if opt in ('-d', '--debug'):

            dConfig['debug'] = True

        elif opt in ('-f', '--forks'):

            try:
            
                dConfig['forks'] = int(arg)

            except ValueError as e:

                bError = True

    if bError: usage()
    else:

        iStart = time.time()

        ### setup producers

        lProducerArgs = []

        for sSearchString in sSearchStrings:

            lProducerArgs.append( (sSearchString, dConfig) )

        # create pool of workers -- number of workers equals the number of search strings to be processed
        oProducerPool = multiprocessing.Pool( processes=len(lProducerArgs) )

        ### do work -- use pool of workers to search for each search string in muse-corpus-source es index
        oProducerPool.map(findBuildFiles, lProducerArgs)

        oProducerPool.close()
        oProducerPool.join()
        
        ### setup consumers
        lConsumerArgs = []

        for i in range(0, dConfig['forks']):

            lConsumerArgs.append( dConfig )

        # create pool of workers
        ##oConsumerPool = multiprocessing.Pool(processes=iForks)

        ### do work -- use pool of workers to descend into each project path recording/ingesting all file names
        ##oConsumerPool.map(findProjectFiles, lConsumerArgs)

        ##oConsumerPool.close()
        ##oConsumerPool.join()

        if dConfig['debug']: debug('func: main()', "all processes completed") 

        iEnd = time.time()

        printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
