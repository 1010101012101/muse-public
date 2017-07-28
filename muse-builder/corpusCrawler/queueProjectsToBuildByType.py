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
import re
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
#from redisHelper import RedisSet

from projectDB import MuseProjectDB
from projectDB import depth

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
# curl -s -XGET 'http://localhost:9200/muse-projects/_search?pretty=true&q=*:*&size=3' | jq .

### get all docs in index (up to 10) with jq pretty print
# curl -s -XGET 'http://localhost:9200/muse-corpus-source/_search?q=*:*' | jq .

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

# get mapping for index
# curl -XGET 'http://localhost:9200/muse-corpus-source/_mapping/files' | jq .

###################

###
#
###
def verifyEncoding(sOriginal):

    sTransformed = ''

    try:

        sTransformed = sOriginal.encode('utf-8')
        #sTransformed = sOriginal.decode('utf-8')

    except (ValueError, UnicodeDecodeError, UnicodeEncodeError) as e:

        try:

            sTransformed = sOriginal.encode('latin-1')
            #sTransformed = sOriginal.decode('latin-1')

        except (ValueError, UnicodeDecodeError, UnicodeEncodeError) as e:

            try:

                sTransformed = sOriginal.encode('utf-16')
                #sTransformed = sOriginal.decode('utf-16')

            except (ValueError, UnicodeDecodeError, UnicodeEncodeError) as e:

                warning('func verifyEncoding(): failed to transform sOriginal:', sOriginal, 'with utf-8, latin-1 and utf-16', e)
                sTransformed = ''

    return sTransformed

###
def indexSourceTargets(dConfig):

    # setup mysql client
    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])
    dMp.open()

    # setup elasticsearch client
    oES = Elasticsearch(dConfig['es-instance-locs'])

    # setup source targets queue
    qRedis = RedisQueue(dConfig['redis-queue-source-targets'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    while 1:

        sQuery = qRedis.get(block=True, timeout=30)

        if sQuery:

            dQuery = json.loads(sQuery)

            if dConfig['debug']: debug( 'func: indexSourceTargets() dQuery:', json.dumps(dQuery) ) 

            lSourceFiles = []

            # scroll time set to 10 minutes, change as needed -- required for consistent results, the scroll token expires at the end of scroll time

            dResponse = oES.search(index=dConfig['es-file-index-name'], doc_type=dConfig['es-file-index-type'], body=json.dumps(dQuery), search_type='scan', scroll='20m', timeout='20m', lowercase_expanded_terms=False)
            sScrollId = dResponse['_scroll_id']

            if dConfig['debug']: debug('func: indexSourceTargets() (after initial search) dResponse: ', dResponse)

            if dConfig['debug']: debug('func: indexSourceTargets() search hits: ', dResponse['hits']['total'])

            #while not dResponse['timed_out'] and dResponse['hits']['hits']['total'] > 0:
            while 'timed_out' in dResponse and not dResponse['timed_out'] and 'hits' in dResponse and 'total' in dResponse['hits'] and dResponse['hits']['total'] > 0:

                dResponse = oES.scroll(scroll_id=sScrollId, scroll='20m')

                sScrollId = dResponse['_scroll_id']

                if ('hits' in dResponse['hits']) and (len(dResponse['hits']['hits']) > 0):

                    if dConfig['debug']: debug('func: indexSourceTargets() scroll_id:', sScrollId, 'number of hits:', len(dResponse['hits']['hits']) )

                    for dHit in dResponse['hits']['hits']:

                        # found matches

                        try:

                            if '_source' in dHit:

                                # debug('func: indexSourceTargets() dHit:', json.dumps(dHit['_source']) )
                                #NATE added, remove leading path from found built targets
                                mBuildTarget=dHit['_source']['file'];
                                mBuildTarget=mBuildTarget.split('/')
                                dHit['_source']['file'] = mBuildTarget[len(mBuildTarget)-1]

                                dProjectFound = {}

                                lSourceTypes = dMp.getSourceTypes()
                                for sSourceType in lSourceTypes:

                                    dProjectFound[sSourceType] = False

                                if 'file' in dHit['_source'] and dHit['_source']['file']:

                                    (sFileName, sFileExt) = os.path.splitext(dHit['_source']['file']) 

                                    if sFileExt.lower() in dConfig['source-targets'].keys():

                                        dProjectFound[ dConfig['source-targets'][ sFileExt.lower() ] ] = True

                                else: 

                                    warning( 'func indexSourceTargets() es returned an improper source target:', json.dumps(dHit['_source']) )
                                    continue

                                if 'project-name' in dHit['_source'] and dHit['_source']['project-name']: dProjectFound['projectName'] = dHit['_source']['project-name']
                                if 'project-path' in dHit['_source'] and dHit['_source']['project-path']: dProjectFound['projectPath'] = dHit['_source']['project-path']
                                if 'path' in dHit['_source'] and dHit['_source']['path']: 

                                    dProjectFound['buildTargetPath'] = verifyEncoding( dHit['_source']['path'] )

                                # debug('func findSourceFileHelper()', json.dumps(dProjectFound))

                                lSourceFiles.append(dProjectFound)

                                # causing es reads to time out
            
                                if (len(lSourceFiles) > dConfig['mysql-bulk-statement-size']) and dConfig['mysql']:

                                    dMp.insertIntoSourceTargets(lTargets=lSourceFiles, bDebug=dConfig['debug'])
                                    printMsg('func indexSourceTargets() loaded', iCtr, 'source targets')

                                    lSourceFiles = []

                        except (UnicodeDecodeError, UnicodeEncodeError) as e:
                            
                            warning('func indexSourceTargets() encountered exception:', e)
                            #warning('func indexSourceTargets() with string: ', dHit['_source']['path'])
                            warning('func indexSourceTargets() full _source payload: ', json.dumps( dHit['_source'], indent=4 ) )

                else:

                    break

                if (len(lSourceFiles) > 0) and dConfig['mysql']:

                    dMp.insertIntoSourceTargets(lTargets=lSourceFiles, bDebug=dConfig['debug'])
                        
                    lSourceFiles = []

        else:

            break

    dMp.close()

###
# initialize targets queues and tables
###
def initTargets(dConfig):

    # flush source targets queue
    qRedis = RedisQueue(dConfig['redis-queue-source-targets'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])
    qRedis.flush()

    # purge build targets queue -- considering if we need to split mysql ingestion from elasticsearch queries... mysql may benefit from consumer pool inserting statements concurrently
    # qRedis = RedisQueue(dConfig['redis-queue-build-targets'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])
    # qRedis.flush()

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])

    dMp.open()

    # truncate sourceTargets table before re-populating
#    dMp.flush(sTable='sourceTargets', bDebug=dConfig['debug'])

    # truncate buildTargets table before re-populating
#    dMp.flush(sTable='buildTargets', bDebug=dConfig['debug'])

    dMp.close()

###
# producer process; finds source targets from projects where build targets don't exist from pre-existing elasticsearch files index
###
def findSourceTargets(dConfig):

    # setup mysql 
    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])
    dMp.open()

    # purge source targets queue
    qRedis = RedisQueue(dConfig['redis-queue-source-targets'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    lProjectRows = dMp.select(sSelectClause='projectName', sTable='cProjectsWithNoBuildTargets', bDebug=dConfig['debug'])

    dMp.close()

    debug('func: findSourceTargets() # of c projects without build targets:', len(lProjectRows) )

    iCtr = 0

    for tProjectRow in lProjectRows:

        iCtr += 1

        if dConfig['debug'] and iCtr > 10: break

        (sProjectName, ) = tProjectRow

        # debug('func: findBuildFiles() c project name:', sProjectName)

        '''
        dQuery = {
            "query": {
                "bool": {
                    "must": [
                        { "bool": {
                            "should": [
                                { "regexp": { "file.raw": ".*\.c" } },
                                { "regexp": { "file.raw": ".*\.cxx" } },
                                { "regexp": { "file.raw": ".*\.c++" } },
                                { "regexp": { "file.raw": ".*\.cc" } }
                            ]
                          }
                        },
                        {
                          "bool": {
                            "should": [
                              { "match": { "path": "latest/*" } },
                              { "match": { "path": "content/*"} }
                            ]
                          }
                        },
                        {
                          "term": { "project-name.raw": sProjectName }
                        }
                    ]
                }
            }
        }
        '''


        '''
        dQuery = {
            "query": {
                "bool": {
                    "must": [
                        { "bool": {
                            "should": [
                                { "term": { "ext.raw": "c" } },
                                { "term": { "ext.raw": "cc" } },
                                { "term": { "ext.raw": "cpp" } },
                                { "term": { "ext.raw": "cxx" } },
                                { "term": { "ext.raw": "c++" } }
                            ]
                          }
                        },
                        {
                          "bool": {
                            "should": [
                              { "match": { "path": "latest/*" } },
                              { "match": { "path": "content/*"} }
                            ]
                          }
                        },
                        {
                          "term": { "project-name.raw": sProjectName }
                        }
                    ]
                }
            }
        }
        '''

        dQuery = {
            "query": {
                "bool": {
                    "must": [
                        { "bool": {
                            "should": [
                                { "term": { "ext.raw": "c" } },
                                { "term": { "ext.raw": "cpp" } },
                                { "term": { "ext.raw": "cxx" } },
                                { "term": { "ext.raw": "c++" } },
                                { "term": { "ext.raw": "cc" } }
                            ]
                          }
                        },
                        {
                          "bool": {
                            "should": [
                              { "match": { "path": "latest/*" } },
                              { "match": { "path": "content/*"} }
                            ]
                          }
                        },
                        {
                          "term": { "project-name.raw": sProjectName }
                        }
                    ]
                }
            }
        }

        qRedis.put( json.dumps(dQuery) ) 

###
# producer process; finds specific build targets from pre-existing elasticsearch files index
###
def findBuildTargets(dConfig):

    # setup mysql client
    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])
    dMp.open()

    # setup elasticsearch client
    oES = Elasticsearch(dConfig['es-instance-locs'],timeout=180, max_retries=3, retry_on_timeout=True )

    # purge build targets queue -- considering if we need to split mysql ingestion from elasticsearch queries... mysql may benefit from consumer pool inserting statements concurrently
    # qRedis = RedisQueue(dConfig['redis-queue-build-targets'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    lBuildFiles = []

    iCtr = 0

    dQuery = {
        "query": {
            "bool": {
                "must": [
                    { "bool": {
                        "should": [
                            { "wildcard": { "file.raw": "*/configure.ac" } },
                            { "wildcard": { "file.raw": "*/configure.in" } },
                            { "wildcard": { "file.raw": "*/configure" } },
                            { "wildcard": { "file.raw": "*/CMakeLists.txt" } },
                            { "wildcard": { "file.raw": "*/Makefile" } }
                        ]
                      }
                    },
                    {
                      "bool": {
                        "should": [
                          { "match": { "path": "latest/*" } },
                          { "match": { "path": "content/*"} }
                        ]
                      }
                    },
                    {"wildcard":{"file.raw": "/data/corpus_8tof/*"}}
                ]
            }
        }
    }

    if dConfig['debug']: debug( 'func: findBuildFiles() dQuery:', json.dumps(dQuery) ) 

    # scroll time set to 10 minutes, change as needed -- required for consistent results, the scroll token expires at the end of scroll time

    dResponse = oES.search(index=dConfig['es-file-index-name'], doc_type=dConfig['es-file-index-type'], body=json.dumps(dQuery), search_type='scan', scroll='20m', timeout='20m', lowercase_expanded_terms=False, request_timeout=180,)
    sScrollId = dResponse['_scroll_id']

    if dConfig['debug']: debug('func: findBuildFiles() (after initial search) dResponse: ', dResponse)

    if dConfig['debug']: debug('func: findBuildFiles() search hits: ', dResponse['hits']['total'])
    debug('func: findBuildFiles() search hits: ', dResponse['hits']['total'])

    while 'timed_out' in dResponse and not dResponse['timed_out'] and 'hits' in dResponse and 'total' in dResponse['hits'] and dResponse['hits']['total'] > 0:

        dResponse = oES.scroll(scroll_id=sScrollId, scroll='20m')

        sScrollId = dResponse['_scroll_id']

        if ('hits' in dResponse['hits']) and (len(dResponse['hits']['hits']) > 0):

            if dConfig['debug']: debug('func: findBuildFiles() scroll_id:', sScrollId, 'number of hits:', len(dResponse['hits']['hits']) )

            if dConfig['debug'] and iCtr > 10: break

            for dHit in dResponse['hits']['hits']:

                iCtr += 1

                if dConfig['debug'] and iCtr > 10: break

                # found matches

                try:

                    if '_source' in dHit:

			#NATE added, remove leading path from found built targets
                        mBuildTarget=dHit['_source']['file'];
                        mBuildTarget=mBuildTarget.split('/')
                        dHit['_source']['file'] = mBuildTarget[len(mBuildTarget)-1]

                        dProjectFound = {}

                        # initialize all build target types to false
                        lBuildTypes = dMp.getBuildTypes()
                        for sBuildType in lBuildTypes:

                            dProjectFound[sBuildType] = False

                        # mark relevant build target type true
                        if 'file' in dHit['_source'] and dHit['_source']['file'] and dHit['_source']['file'] in dConfig['build-targets'].keys():

                            if dConfig['debug']: debug('func findBuildFiles() returned build target:', dHit['_source']['file'])

                            dProjectFound[ dConfig['build-targets'][ dHit['_source']['file'] ]['type'] ] = True
                            dProjectFound['ranking'] = dConfig['build-targets'][ dHit['_source']['file'] ]['ranking']

                        else: 

                            warning( 'func findBuildFiles() es returned an improper build target:', json.dumps(dHit['_source']) )
                            continue

                        if 'project-name' in dHit['_source'] and dHit['_source']['project-name']: dProjectFound['projectName'] = dHit['_source']['project-name']
                        if 'project-path' in dHit['_source'] and dHit['_source']['project-path']: dProjectFound['projectPath'] = dHit['_source']['project-path']
                        if 'path' in dHit['_source'] and dHit['_source']['path']: 

                            dProjectFound['buildTargetPath'] = verifyEncoding( dHit['_source']['path'] )
                            dProjectFound['depth'] = depth( dProjectFound['buildTargetPath'] )

                        # debug('func findBuildFiles()', json.dumps(dProjectFound))

                        lBuildFiles.append(dProjectFound)

                        # causing es reads to time out
    
                        if (len(lBuildFiles) > dConfig['mysql-bulk-statement-size']) and dConfig['mysql']:

                            dMp.insertIntoBuildTargets(lTargets=lBuildFiles, bDebug=dConfig['debug'])
                            printMsg('func findBuildFiles() loaded', iCtr, 'build targets')

                            lBuildFiles = []

                except (UnicodeDecodeError, UnicodeEncodeError) as e:
                    
                    warning('func findBuildFiles() encountered exception:', e)
                    #warning('func findBuildFiles() with string: ', dHit['_source']['path'])
                    warning('func findBuildFiles() full _source payload: ', json.dumps( dHit['_source'], indent=4 ) )

        else:

            break

        if (len(lBuildFiles) > 0) and dConfig['mysql']:

            dMp.insertIntoBuildTargets(lTargets=lBuildFiles, bDebug=dConfig['debug'])
                
            lBuildFiles = []

    dMp.close()

###
# initialize projects queue and table
###
def initProjects(dConfig):

    # flush project queue; queue used to traverse projects (reset every time)
    qRedis = RedisQueue(dConfig['redis-queue-project-paths'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])
    qRedis.flush()

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])

    dMp.open()

    # ensure projects table is empty before adding project crawl
#Nate   dMp.flush(sTable='projects',bDebug=dConfig['debug'])
#Nate want to preserve projects table b/c I am adding the second half of corpus to it

    dMp.close()

###
# producer process that populates temp redis queue with project path roots to traverse through
###
def findProjects(sCorpusPath, dConfig):

    qRedis = RedisQueue(dConfig['redis-queue-project-paths'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    iCount = 0

    for sRoot, lDirs, lFiles in os.walk(sCorpusPath):

        iLevel = sRoot.count(os.sep)

        if iLevel >= 11:

            del lDirs[:]

        if iLevel == 11:

            if dConfig['debug']: debug('func: findProjects()', 'projects-root:', sRoot, iLevel)
            debug('func: findProjects()', 'projects-root:', sRoot, iLevel)
            
            qRedis.put(sRoot)
            
            iCount += 1

            if dConfig['debug'] and iCount >= 10: break

    printMsg('func: findProjects()', str(iCount), 'projects loaded into queue for processing')

###
# consumer process that populates mysql('projects') with project names from /data/corpus_0to7 or 8tof
###
def processProjects(dConfig):

    qRedis = RedisQueue(dConfig['redis-queue-project-paths'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])
    dMp.open()

    lProjects = []

    iCount = 0

    while 1:

        sRoot = qRedis.get(block=True, timeout=30)

        if sRoot:

            dProject = {
                '_index': dConfig['es-project-index-name'],
                '_type': dConfig['es-project-index-type'],
                '_source': {}
            }

            dProject['_id'] = os.path.basename(sRoot)
            dProject['_source']['name'] = os.path.basename(sRoot)
            debug('func: processProjects() projects-root:', sRoot) 

            if dConfig['debug']: 

                debug('func: processProjects() projects-root:', sRoot) 
                debug('func: processProjects() projects _id and _source[name] :', dProject['_id']) 
                debug('func: processProjects() inserting project:', dProject['_source']['name'])

            if os.path.isfile( os.path.join(sRoot, 'filter.json') ):

                with open( os.path.join(sRoot, 'filter.json') ) as fProjectFilter:

                    dProjectFilter = json.load(fProjectFilter)

                    if 'hasBytecode' in dProjectFilter and dProjectFilter['hasBytecode'].lower() != 'none':
                        dProject['_source']['bytecode_available'] = True

            if os.path.isfile( os.path.join(sRoot, 'index.json') ):

                with open( os.path.join(sRoot, 'index.json') ) as fProjectIndex:
            
                    dProjectIndex = json.load(fProjectIndex)

                    if dConfig['debug']: debug('func: processProjects() dProjectIndex.keys():', json.dumps(dProjectIndex.keys(), indent=4) )

                    '''
                    if 'bytecode_available' in dProjectIndex and dProjectIndex['bytecode_available']:

                        dProject['_source']['bytecode_available'] = True
                    '''
                    if 'code' in dProjectIndex:

                        dProject['_source']['source'] = True
                        dProject['_source']['codeDir'] = dProjectIndex['code']

                        if dProject['_source']['codeDir'].startswith('./'):

                            dProject['_source']['codeDir'] = dProject['_source']['codeDir'][len('./'):]

                    if 'site' in dProjectIndex:

                        dProject['_source']['site'] = dProjectIndex['site']

                    if 'crawler_metadata' in dProjectIndex:

                        for sMetaDataFile in dProjectIndex['crawler_metadata']:

                            if 'languages.json' in sMetaDataFile:

                                sLanguageFile = os.path.join(sRoot, sMetaDataFile)

                                if os.path.isfile(sLanguageFile):

                                    with open(sLanguageFile) as fLanguageFile:

                                        dLanguageFile = json.load(fLanguageFile)

                                        if 'C' in dLanguageFile: 

                                            dProject['_source']['c'] = dLanguageFile['C']

                                        if 'C++' in dLanguageFile: 

                                            dProject['_source']['cpp'] = dLanguageFile['C++']

                                        if 'C#' in dLanguageFile:

                                            dProject['_source']['csharp'] = dLanguageFile['C#']

                                        if 'Java' in dLanguageFile: 

                                            dProject['_source']['java'] = dLanguageFile['Java']

                                        if dConfig['debug']: debug('func: findProjects() dLanguageFile:', json.dumps(dLanguageFile, indent=4) )
                                else:

                                    warning('func: processProjects()', 'languages.json file listed in index.json but does not exist for project:', dProject['_source']['name'], 'at listed location:', sLanguageFile)

            else:

                warning('func: processProjects()', 'index.json not found for project:', dProject['_source']['name'])

            lProjects.append(dProject)
            
            iCount += 1

            if (iCount % dConfig['mysql-bulk-statement-size']) == 0: 

                dMp.insertIntoProjects(lProjects=lProjects, bDebug=dConfig['debug'])
                lProjects = []

            if dConfig['debug'] and iCount >= 100: break

        else:

            break

    if dConfig['mysql']:

        if len(lProjects) > 0:

            dMp.insertIntoProjects(lProjects=lProjects, bDebug=dConfig['debug'])
            lProjects = []

        dMp.close()

    return lProjects

###
def initBuildQueues(dConfig):

    # purge in-progress queue
    qRedis = RedisQueue(dConfig['redis-queue-building'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])
    qRedis.flush()
    
    # purge to-build queue
    qRedis = RedisQueue(dConfig['redis-queue-to-build'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])
    qRedis.flush()

###
def queueUpBuildTargets(dConfig):

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])
    
    # setup to-build queue
    qRedis = RedisQueue(dConfig['redis-queue-to-build'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    dMp.open()

    # get projects first to iterate through (makes it easier to build project specific dictionaries), limit if in debug mode

    iProjectCount = 0
    iTargetCount = 0
    iMultiTargets = 0

    sLimitClause = ''

    if dConfig['debug']: sLimitClause = '10'
    
    lLeadingPaths = []
    
    dProject = {}

    dCodeDirLookup = {}
    lProjectRows = dMp.select(sSelectClause='projectName,codeDir', sTable='availableProjects', bDebug=dConfig['debug'])
    for tProjectRow in lProjectRows:

        (sProjectName, sCodeDir) = tProjectRow
        dCodeDirLookup[sProjectName] = sCodeDir
    
    lTargetRows = []

    if dConfig['unBuiltProjectsOnly']:

        if dConfig['queueSite']:

            lTargetRows = dMp.select(sSelectClause='projectName,projectPath,buildTargetPath', sTable='unBuiltTargetsWithSite', sWhereClause='site=\'' + dConfig['queueSite'] + '\'', sOrderByClause='projectName,ranking', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

        else:

            lTargetRows = dMp.select(sSelectClause='projectName,projectPath,buildTargetPath', sTable='unBuiltTargets', sOrderByClause='projectName,ranking', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

    else:

        if dConfig['queueSite']:

            lTargetRows = dMp.select(sSelectClause='projectName,projectPath,buildTargetPath', sTable='availableTargetsWithSite', sWhereClause='site=\'' + dConfig['queueSite'] + '\'', sOrderByClause='projectName,ranking', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

        else:

            lTargetRows = dMp.select(sSelectClause='projectName,projectPath,buildTargetPath', sTable='availableTargets', sOrderByClause='projectName,ranking', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

    dMp.close()

    for tTargetRow in lTargetRows:

        dTarget = {}

        (sProjectName, sProjectPath, dTarget['buildTargetPath'], ) = tTargetRow

        dTarget['buildType'] = dConfig['build-targets'][os.path.basename(dTarget['buildTargetPath'])]['type']

        (sLeadingPath, sTarget) = os.path.split(dTarget['buildTargetPath'])
         
        # NATE remove leading tarball from path
        sLeadingPath = re.sub(r'[a-zA-Z_0-9-_]*.tgz/', "", sLeadingPath)
        dTarget['buildTargetPath'] = os.path.join(sLeadingPath, sTarget)

        # NATE added to grab code directory from buildTargetPath
        bPath=sLeadingPath.split('/')
        if len(bPath) > 1 :
           codedir2=bPath[0]

        iTargetCount += 1

        if 'projectName' in dProject :

            if dProject['projectName'] != sProjectName:

                # new project encountered, push old project onto queue
                if dConfig['debug']: debug('func: queueUpBuildTargets() queuing project:', json.dumps(dProject, indent=4))
                qRedis.put(json.dumps(dProject))
                iProjectCount += 1
                if len(lLeadingPaths) > 1:
                    iMultiTargets += 1

                dProject = {
                    'projectName': sProjectName,
                    'projectPath': sProjectPath,
                    'version': dConfig['version'],
                    'targets': [ dTarget ],
                    'codeDir': codedir2
                    #'codeDir': dCodeDirLookup[sProjectName]
                }

                lLeadingPaths = [ sLeadingPath ]

            else:

                if sLeadingPath not in lLeadingPaths:

                    dProject['targets'].append(dTarget)
                    lLeadingPaths.append(sLeadingPath)

                else: 

                    iTargetCount += -1
                    if dConfig['debug']: debug('func: queueUpBuildTargets() already encountered path:',  sLeadingPath, 'not adding:', json.dumps(dTarget, indent=4))

        else:

            dProject = {
                'projectName': sProjectName,
                'projectPath': sProjectPath,
                'version': dConfig['version'],
                'targets': [ dTarget ],
                'codeDir': dCodeDirLookup[sProjectName]
            }

            lLeadingPaths = [ sLeadingPath ]

    if dConfig['debug']: debug('func: queueUpBuildTargets() queuing project:', json.dumps(dProject, indent=4))

    qRedis.put(json.dumps(dProject))
    iProjectCount += 1        
    if len(lLeadingPaths) > 1:
        iMultiTargets += 1

    printMsg('func: queueUpBuildTargets()', str(iProjectCount), 'projects queued', str(iTargetCount), 'targets queued', str(iMultiTargets), 'multi-target projects queued')
    printMsg('func: queueUpBuildTargets()', qRedis.size(), 'projects reported by redis')

###
def queueUpSourceTargets(dConfig):

    if dConfig['mysql'] and dConfig['redis']:

        dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])
        
        # setup to-build queue
        qRedis = RedisQueue(dConfig['redis-queue-to-build'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])
        
        dMp.open()

        # get projects first to iterate through (makes it easier to build project specific dictionaries), limit if in debug mode
        iProjectCount = 0
        iTargetCount = 0
        iMultiTargets = 0

        sLimitClause = ''

        if dConfig['debug']: sLimitClause = '10'
        
        lLeadingPaths = []
        
        dProject = {}

        dCodeDirLookup = {}
        lProjectRows = dMp.select(sSelectClause='projectName,codeDir', sTable='availableProjects', bDebug=dConfig['debug'])
        for tProjectRow in lProjectRows:

            (sProjectName, sCodeDir) = tProjectRow
            dCodeDirLookup[sProjectName] = sCodeDir
        
        lTargetRows = []

        if dConfig['unBuiltProjectsOnly']:

            if dConfig['queueSite']:

                lTargetRows = dMp.select(sSelectClause='projectName,projectPath,buildTargetPath', sTable='unBuiltSourceTargetsWithSite', sWhereClause='site=\'' + dConfig['queueSite'] + '\'', sOrderByClause='projectName', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

            else:

                lTargetRows = dMp.select(sSelectClause='projectName,projectPath,buildTargetPath', sTable='unBuiltSourceTargets', sOrderByClause='projectName', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

        else:

            if dConfig['queueSite']:

                lTargetRows = dMp.select(sSelectClause='projectName,projectPath,buildTargetPath', sTable='availableSourceTargetsWithSite', sWhereClause='site=\'' + dConfig['queueSite'] + '\'', sOrderByClause='projectName', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

            else:

                lTargetRows = dMp.select(sSelectClause='projectName,projectPath,buildTargetPath', sTable='availableSourceTargets', sOrderByClause='projectName', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

        dMp.close()

        for tTargetRow in lTargetRows:

            dTarget = {}

            (sProjectName, sProjectPath, dTarget['buildTargetPath'], ) = tTargetRow

            (_, sFileExt) = os.path.splitext( os.path.basename(dTarget['buildTargetPath']) )

            if sFileExt:

                sFileExt = sFileExt.lower()

                if sFileExt in dConfig['source-targets'].keys():

                    dTarget['buildType'] = dConfig['source-targets'][sFileExt]

                    (sLeadingPath, sTarget) = os.path.split(dTarget['buildTargetPath'])

                    # NATE remove leading tarball from path
                    sLeadingPath = re.sub(r'[a-zA-Z_0-9-_]*.tgz/', "", sLeadingPath)
                    dTarget['buildTargetPath'] = os.path.join(sLeadingPath, sTarget)

                    # NATE added to grab code directory from buildTargetPath
                    bPath=sLeadingPath.split('/')
                    if len(bPath) > 1 :
                        codedir2=bPath[0]

                    iTargetCount += 1

                    if 'projectName' in dProject :

                        if dProject['projectName'] != sProjectName:

                            # new project encountered, push old project onto queue
                            if dConfig['debug']: debug('func: queueUpSourceTargets() queuing project:', json.dumps(dProject, indent=4))
                            qRedis.put(json.dumps(dProject))
                            iProjectCount += 1
                            if len(lLeadingPaths) > 1:
                                iMultiTargets += 1

                            dProject = {
                                'projectName': sProjectName,
                                'projectPath': sProjectPath,
                                'version': dConfig['version'],
                                'targets': [ dTarget ],
                                'codeDir': codedir2
                                #'codeDir': dCodeDirLookup[sProjectName]
                            }

                            lLeadingPaths = [ sLeadingPath ]

                        else:

                            if sLeadingPath not in lLeadingPaths:

                                dProject['targets'].append(dTarget)
                                lLeadingPaths.append(sLeadingPath)

                            else: 

                                iTargetCount += -1
                                if dConfig['debug']: debug('func: queueUpSourceTargets() already encountered path:',  sLeadingPath, 'not adding:', json.dumps(dTarget, indent=4))

                    else:

                        dProject = {
                            'projectName': sProjectName,
                            'projectPath': sProjectPath,
                            'version': dConfig['version'],
                            'targets': [ dTarget ],
                            'codeDir': dCodeDirLookup[sProjectName]
                        }

                        lLeadingPaths = [ sLeadingPath ]

                else:

                    warning('func: queueUpSourceTargets() unknown C/C++ file extension encountered:', sFileExt, 'file-path:',dTarget['buildTargetPath'],'for project:', sProjectName)

            else:

                warning('func: queueUpSourceTargets() missing file extension encountered file-path:') #,dTarget['buildTargetPath'],'for project:', sProjectName)


        if dConfig['debug']: debug('func: queueUpSourceTargets() queuing project:', json.dumps(dProject, indent=4))

        qRedis.put(json.dumps(dProject))
        iProjectCount += 1        
        if len(lLeadingPaths) > 1:
            iMultiTargets += 1

        printMsg('func: queueUpSourceTargets()', str(iProjectCount), 'projects queued', str(iTargetCount), 'targets queued', str(iMultiTargets), 'multi-target projects queued')
        printMsg('func: queueUpSourceTargets()', qRedis.size(), 'projects reported by redis')
        
###
def usage():
    warning('Usage: queueProjectsToBuildByType.py --corpus-dir-path=/data/corpus_0to7 --forks=5 --analyze-projects --crawl-projects --unbuilt-projects-only --queue-projects --debug')

###
def main(argv):

    # defaults
    bError = False
    sCorpusPath = '/data/corpus_0to7'

    dConfig = {}

    dConfig['analyze-projects'] = False
    dConfig['crawl-projects'] = False

    dConfig['debug'] = False

    dConfig['es-bulk-chunk-size'] = 500
    dConfig['es-instance-locs'] = ['muse1-int','muse2-int','muse3-int']
    # dConfig['es-instance-locs'] = ['muse1-int','muse2-int']
    #dConfig['es-instance-locs'] = ['muse3-int']
    
    dConfig['es-file-index-name'] = 'muse-corpus-source-new'
    dConfig['es-file-index-type'] = 'files'

    dConfig['es-project-index-name'] = 'muse-projects'
    dConfig['es-project-index-type'] = 'projects'

    dConfig['forks'] = 5

    dConfig['mysql-db'] = 'muse'
    dConfig['mysql-user'] = 'muse'
    dConfig['mysql-passwd'] = 'muse'
    dConfig['mysql-loc'] = 'muse2-int'
    dConfig['mysql-port'] = 54321 
    dConfig['mysql'] = True
    dConfig['mysql-bulk-statement-size'] = 100

    dConfig['queueUpFilesForBuilding'] = False
    dConfig['queueSite'] = ''

    dConfig['redis-queue-to-build'] = 'muse-to-build'
    dConfig['redis-queue-building'] = 'muse-building'
    # dConfig['redis-queue-build-targets'] = 'muse-build-targets'
    dConfig['redis-queue-project-paths'] = 'muse-project-paths'
    dConfig['redis-queue-source-targets'] = 'muse-source-targets'
    dConfig['redis-loc'] = 'muse2-int'
    dConfig['redis-port'] = '12345'
    dConfig['redis'] = True

    dConfig['time-stamp'] = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
    dConfig['unBuiltProjectsOnly'] = False
    dConfig['version'] = '1.0'

    dConfig['build-targets'] = {
        'configure' : { 'type' : 'configureBuildType', 'ranking': 4 },
        'configure.ac' : { 'type' : 'configureacBuildType', 'ranking': 2 },
        'configure.in' : { 'type' : 'configureinBuildType', 'ranking': 3 },
        'CMakeLists.txt' : { 'type' : 'cmakeBuildType', 'ranking': 1 },
        'Makefile' : { 'type' : 'makefileBuildType', 'ranking': 5 }
        #'build.xml' : { 'type' : 'antBuildType',  'ranking': 7 },
        #'pom.xml' : { 'type' : 'mavenBuildType', 'ranking': 6 }
    }

    dConfig['source-targets'] = {
        '.c' : 'cBuildType',
        '.cc' : 'cppBuildType',
        '.cpp' : 'cppBuildType',
        '.cxx' : 'cppBuildType',
        '.c++' : 'cppBuildType'
    }

    ### command line argument handling
    options, remainder = getopt.getopt(sys.argv[1:], 'c:f:apuqs:d', ['corpus-dir-path=','forks=','analyze-projects','crawl-projects','unbuilt-projects-only','queue-projects','queue-site=','debug'])

    debug('func: main()', 'options:', options)
    debug('func: main()', 'remainder:', remainder)

    for opt, arg in options:

        if opt in ('-c', '--corpus-dir-path'):

            sCorpusPath = arg

        elif opt in ('-f', '--forks'):

            dConfig['forks'] = arg

        elif opt in ('-a', '--analyze-projects'):

            dConfig['analyze-projects'] = True

        elif opt in ('-p', '--crawl-projects'):

            dConfig['crawl-projects'] = True

        elif opt in ('-q', '--queue-projects'):

            dConfig['queueUpFilesForBuilding'] = True

        elif opt in ('-s', '--queue-site'):

            dConfig['queueSite'] = arg

        elif opt in ('-u', '--unbuilt-projects-only'):

            dConfig['unBuiltProjectsOnly'] = True

        elif opt in ('-d', '--debug'):

            dConfig['debug'] = True

    # debug(json.dumps(dConfig, indent=4))

    if dConfig['crawl-projects'] and not os.path.isdir(sCorpusPath): bError = True

    if bError: usage()
    else:

        iStart = time.time()

        ### setup producers

        if dConfig['crawl-projects']:

            # initialize projects table/queue
            initProjects(dConfig)

            # call producer process that populates mysql with project names from sCorpusPath 
            pfindProjects = multiprocessing.Process( target=findProjects, args=(sCorpusPath, dConfig) )
            pfindProjects.start()

            # create pool of workers
            oProcessProjectsPool = multiprocessing.Pool(processes=dConfig['forks'])

            lArgs = []

            for i in range(0, dConfig['forks']):

                lArgs.append(dConfig)

            ### do work -- use pool of workers to index source targets
            oProcessProjectsPool.map(processProjects, lArgs)

            pfindProjects.join()

            oProcessProjectsPool.close()
            oProcessProjectsPool.join()

        elif dConfig['analyze-projects']:

            # initialize targets table/queue
            initTargets(dConfig)

            pBuildTargets = multiprocessing.Process( target=findBuildTargets, args=(dConfig, ) )
            pBuildTargets.start()
        
            pBuildTargets.join()

            pSourceTargets = multiprocessing.Process( target=findSourceTargets, args=(dConfig, ) )
            pSourceTargets.start()

            # create pool of workers
            oSourceTargetIndexerPool = multiprocessing.Pool(processes=dConfig['forks'])

            lArgs = []

            for i in range(0, dConfig['forks']):

                lArgs.append(dConfig)

            ### do work -- use pool of workers to index source targets
            oSourceTargetIndexerPool.map(indexSourceTargets, lArgs)

            pSourceTargets.join()

            oSourceTargetIndexerPool.close()
            oSourceTargetIndexerPool.join()

        elif dConfig['queueUpFilesForBuilding']:

            initBuildQueues(dConfig=dConfig)
            queueUpBuildTargets(dConfig=dConfig)
            queueUpSourceTargets(dConfig=dConfig)

        if dConfig['debug']: debug('func: main()', "all processes completed") 

        iEnd = time.time()

        printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
