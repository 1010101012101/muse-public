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
# curl http://localhost:9200

### check elasticsearch index health status
# curl -XGET 'http://localhost:9200/_cluster/health?pretty=true'

### check node configuration
# curl -XGET 'http://localhost:9200/_nodes' | jq .

### check index size
#  curl 'localhost:9200/_cat/indices?v'

### index stats 
# curl http://localhost:9200/_stats?pretty=true

### get indexes & aliases
# curl http://localhost:9200/_aliases?pretty=true

### delete index
# curl -XDELETE 'http://localhost:9200/muse-corpus-source/?pretty=true'

#wildcard?
# curl -XDELETE 'http://localhost:9200/muse-corpus*/?pretty=true'

# should delete all indexes
### curl -XDELETE 'http://localhost:9200/_all/?pretty=true'

# curl -XDELETE 'http://localhost:9200/muse-corpus-source/?pretty=true'

### get all docs in index (up to 10)
# curl -s -XGET 'http://localhost:9200/muse-corpus-source/_search?pretty=true&q=*:*'

### get all docs in index (up to 10,000)
# curl -s -XGET 'http://localhost:9200/muse-corpus-source/_search?pretty=true&q=*:*&size=10000' | less

### count number of docs per index
# curl -XGET 'http://localhost:9200/muse-corpus-source/muse-project-files/_count'

### count number of docs per type in an index
# curl "localhost:9200/muse-corpus-source/_search?search_type=count" -d '{
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
def findProjectFiles(tTup):

    (sProjectPath, oES, dConfig) = tTup
    sProjectName = os.path.basename(sProjectPath)
    

    oES = Elasticsearch(dConfig['es-instance-locs'])

    lIgnoreDirs = ['.git','.svn']

    lProjectFiles = []

    if dConfig['debug']: debug('func: findProjectFiles()', 'project-path:', sProjectPath, 'project-name:', sProjectName)

    for sRoot, lDirs, lFiles in os.walk(sProjectPath):

        if len(lProjectFiles) > dConfig['es-bulk-chunk-size']:

            # ingest chunk into elasticsearch
            (iSuccess, lResponse) = helpers.bulk(client=oES, actions=lProjectFiles, timeout="20m", request_timeout=120.)

            if iSuccess < dConfig['es-bulk-chunk-size']:
                warning('func: findProjectFiles() iSuccess:', iSuccess, ' expected:', dConfig['es-bulk-chunk-size'])
                warning('func: findProjectFiles()', type(lResponse), 'returned by bulk api')
                warning('func: findProjectFiles()', json.dumps(lResponse, indent=4), 'returned by bulk api')

            #del lProjectFiles[0 : len(lProjectFiles)]
            lProjectFiles = []

            if dConfig['debug']: debug('func: findProjectFiles()', str( len(lProjectFiles) ), 'files loaded into elasticsearch')

        for sFile in lFiles:

            # make sure dProject is emptied each loop iteration
            dProject = {
                '_index': dConfig['es-index-name'],
                '_type': dConfig['es-index-type'],
                '_source': {
                    'project-path': sProjectPath,
                    'project-name': sProjectName,
                    'crawl-time': dConfig['time-stamp']
                }
            }

            sFilePath = os.path.join(sRoot, sFile)
            sRelPath = os.path.relpath(sFilePath, sProjectPath)

            sDecodedFile = ''
            sDecodedRelPath = ''
            sEncodedWith = ''

            try:

                sDecodedFile = sFile.decode('utf-8')
                sDecodedRelPath = sRelPath.decode('utf-8')
                sEncodedWith = 'utf-8'

            except (ValueError, UnicodeDecodeError) as e:

                try:

                    sDecodedFile = sFile.decode('latin-1')
                    sDecodedRelPath = sRelPath.decode('latin-1')
                    sEncodedWith = 'latin-1'

                except (ValueError, UnicodeDecodeError) as e:

                    try:

                        sDecodedFile = sFile.decode('utf-16')
                        sDecodedRelPath = sRelPath.decode('utf-16')
                        sEncodedWith = 'utf-16'

                    except (ValueError, UnicodeDecodeError) as e:

                        warning('func findProjectFiles():', 'sProjectPath:', dProject['_source']['project-path'], 'sProjectName:', dProject['_source']['project-name'], 'sFile:', sFile, 'sRelPath:', sRelPath, 'utf-8, latin-1, and utf-16 decoding failed', 'exception:', e)

                        sDecodedFile = ''
                        sDecodedRelPath = ''
                        sEncodedWith = ''

            if sDecodedFile and sDecodedRelPath:

                dProject['_source']['file'] = sDecodedFile
                (_,sFileExt) = os.path.splitext(sDecodedFile) 
                if sFileExt:
                    dProject['_source']['ext'] = sFileExt[1:].lower()
                dProject['_source']['path'] = sDecodedRelPath

                if dConfig['debug']: debug('func: findProjectFiles() dProject:', dProject, 'encoded with', sEncodedWith)

                lProjectFiles.append( dProject )

        lDirs[:] = [ sDir for sDir in lDirs if sDir not in lIgnoreDirs ]

    # ingest any stragglers remaining into elasticsearch
    (iSuccess, lResponse) = helpers.bulk(client=oES, actions=lProjectFiles, timeout="20m", request_timeout=120.)
    
    if iSuccess < len(lProjectFiles):
        warning('func: findProjectFiles() iSuccess:', iSuccess, ' expected:', len(lProjectFiles))
        warning('func: findProjectFiles()', type(lResponse), 'returned by bulk api')
        warning('func: findProjectFiles()', json.dumps(lResponse, indent=4), 'returned by bulk api')

    # del lProjectFiles[0 : len(lProjectFiles)]
    lProjectFiles = []

    # if dConfig['debug']: debug('func: findProjectFiles()', str( len(lProjectFiles) ), 'files loaded into elasticsearch')

###
# consumer process that reads off redis queue and processes each project
###
def processProjects(dConfig):

    qRedis = RedisQueue(dConfig['redis-queue-name'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])
    oES = Elasticsearch(dConfig['es-instance-locs'])

    while 1:

        # get next project to process
        sProjectPath = qRedis.get(block=True, timeout=30)

        if sProjectPath:

            findProjectFiles( (sProjectPath, oES, dConfig) )
            
        else:

            break
###
# producer process that populates redis queue with project path roots
###
def findProjects(qRedis, sCorpusPath, dConfig):

    lProjectPaths = []

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

            if dConfig['debug'] and iCount >= 10: break

    printMsg('func: findProjects()', str(iCount), 'projects loaded into queue for processing')

    return lProjectPaths

###
def createESIndex(dConfig):

    oES = Elasticsearch(dConfig['es-instance-locs'])

    # delete index if it exists
    if oES.indices.exists(index=dConfig['es-index-name']):

        oES.indices.delete(index=dConfig['es-index-name'], timeout="20m")

    # create empty index
    oES.indices.create(
        index=dConfig['es-index-name'],
        body={
          'settings': {
            # just one shard, no replicas for testing
            'number_of_shards': 5,
            'number_of_replicas': 0,

            # custom analyzer for analyzing file paths
          }
        },
        timeout="20m"
        # ignore already existing index
        # ignore=400
    )

    ### initialize mapping in elasticsearch to ensure that the "file" attribute is not analyzed

    # mapping of non_analyzed and analyzed fields
    dMultifieldMapping = {
        "type": "string",
        "fields": {
            "raw":   { "type": "string", "index": "not_analyzed" }
        }
    }

    oES.indices.put_mapping(
        index=dConfig['es-index-name'],
        doc_type=dConfig['es-index-type'],
        body={
          dConfig['es-index-type']: {
            'dynamic': 'strict',
            'properties': {
              'file': dMultifieldMapping,
              'ext': dMultifieldMapping,
              'path': dMultifieldMapping,
              'project-name': dMultifieldMapping,
              'project-path': dMultifieldMapping,
              'crawl-time': {
                 "type": "date",
                 "format": "yyyy-MM-dd HH:mm:ss",
                 "store": "yes"
                }
            }
          }
        },
        timeout="20m"
    )
    
    return oES

###
def turnReplicationOn(oES, dConfig):

    oES.indices.put_settings(
        index=dConfig['es-index-name'],
        body={
            "index" : {
                "number_of_replicas" : 1
            }
        }
    )

###
def usage():
    warning('Usage: corpusInspector.py --corpus-dir-path=/data/corpus --forks=5 --redis --debug')
    warning('Usage: Please note that above directory arguments are defaults if not supplied and both directories must exist on the filesystem.')
    warning('Usage: if mode is supplied, it must be either set to thread or process. thread is the default.')

###
def main(argv):

    # defaults
    sCorpusPath = '/data/corpus'

    dConfig = {}
    dConfig['es-bulk-chunk-size'] = 500
    dConfig['debug'] = False
    # binding to muse2 doesn't work right now
    dConfig['es-instance-locs'] = ['muse1-int','muse2-int','muse3-int']
    #dConfig['es-instance-locs'] = ['muse2-int','muse3-int']
    #dConfig['es-instance-locs'] = ['muse3-int']
    dConfig['es-index-name'] = 'muse-corpus-source'
    dConfig['es-index-type'] = 'files'
    dConfig['redis-queue-name'] = 'muse-project-paths'
    dConfig['redis-loc'] = 'muse2-int'
    dConfig['redis-port'] = '12345'
    dConfig['redis'] = False

    dConfig['time-stamp'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    iForks = 5
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

        oES = createESIndex(dConfig)

        ### setup producer

        lProjectPaths = []

        if dConfig['redis']:

            qRedis = RedisQueue(dConfig['redis-queue-name'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

            # ensure redis queue is empty prior to starting consumers
            #qRedis.flush()

            # call producer process that populates redis queue with project path roots
            
            pProducer = multiprocessing.Process( target=findProjects, args=(qRedis, sCorpusPath, dConfig) )
            pProducer.start()

        else:
        
            lProjectPaths = findProjects(None, sCorpusPath, iForks, dConfig)

        ### setup consumers
        lArgs = []

        iForks = 1

        if dConfig['redis']: 

            # create pool of workers
            oPool = multiprocessing.Pool(processes=iForks)

            for i in range(0, iForks):

                lArgs.append(dConfig)

            ### do work -- use pool of workers to descend into each project path recording/ingesting all file names
            oPool.map(processProjects, lArgs)
            pProducer.join()

            oPool.close()
            oPool.join()

        else:

            for sPath in lProjectPaths:

                findProjectFiles( (sPath, oES, dConfig) )

        if dConfig['debug']: debug('func: main()', "all processes completed") 

        # es index was created with replication turned off for speed, turn on replicating shards
        turnReplicationOn(oES, dConfig)

        # refresh to make the documents available for search
        oES.indices.refresh(index=dConfig['es-index-name'])

        # and now we can count the documents
        printMsg('func: main()', 'number of documents in', dConfig['es-index-name'], 'index: ', oES.count(index=dConfig['es-index-name'])['count'])

        iEnd = time.time()

        printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
