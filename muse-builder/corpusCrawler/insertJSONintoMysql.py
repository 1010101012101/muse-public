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
import socket
import subprocess
import sys
import time
import traceback

from elasticsearch import Elasticsearch
from elasticsearch import helpers

from locallibs import debug
from locallibs import printMsg
from locallibs import warning

from projectDB import MuseProjectDB

from redisHelper import RedisQueue
from redisHelper import RedisSet

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

#### curl -XDELETE 'http://localhost:9200/muse-corpus-build-redis/?pretty=true'
#### curl -XDELETE 'http://localhost:9200/muse-corpus-build/?pretty=true'

#wildcard?
# curl -XDELETE 'http://localhost:9200/muse-corpus*/?pretty=true'

# should delete all indexes
### curl -XDELETE 'http://localhost:9200/_all/?pretty=true'

# curl -XDELETE 'http://localhost:9200/muse-corpus-source/?pretty=true'

### get all docs in index (up to 10)
# curl -s -XGET 'http://localhost:9200/muse-corpus-source/_search?pretty=true&q=*:*'

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

###################

###
# global mutex using a locking semaphore
###
lock = None

###
# initializes the locking semaphore
###
def initialize_lock(l):
   global lock
   lock = l

###
# producer process; provides build status to mysql and elasticsearch
###
def postBuildStatusUpdates(dArgs, bjson, dConfig):

    dBuildArgs = {}

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])

    dBuildArgs['projectName'] = bjson['projectName']    
    dBuildArgs['projectPath'] = bjson['sourcePath']     
    dBuildArgs['buildTarPath'] = bjson['builds'][0]['buildTarPath']
    dBuildArgs['targets'] = bjson['builds'][0]['targets']    
#    dBuildArgs['builder'] = bjson['containerName']
    dBuildArgs['buildTime'] = bjson['builds'][0]['buildTime']
    dBuildArgs['version'] = bjson['builds'][0]['version']
    dBuildArgs['os'] = bjson['builds'][0]['os']
    dBuildArgs['numObjectsPreBuild'] = bjson['builds'][0]['numObjectsPreBuild']
    dBuildArgs['numObjectsPostBuild'] = bjson['builds'][0]['numObjectsPostBuild']
    dBuildArgs['numObjectsGenerated'] = bjson['builds'][0]['numObjectsGenerated']
    dBuildArgs['numSources'] = bjson['builds'][0]['numSources']
    dBuildArgs['returnCode'] = bjson['builds'][0]['targets'][0]['returnCode'] 

    #debug("BuildArgs: ", dBuildArgs)

    if dConfig['debug']: debug( 'func: postBuildStatusUpdates() build args prepared for mysql ingestion')

    # commit status to database
    dMp.open()
    dMp.insertIntoBuildStatusTargets(dArgs=dBuildArgs, bDebug=dConfig['debug'])
    dMp.insertIntoBuildStatus(dArgs=dBuildArgs, bDebug=dConfig['debug'])
    dMp.close()

    if dConfig['debug']: debug( 'func: postBuildStatusUpdates() build status ingested into mysql')


###
def main(argv):

    # defaults
    bError = False

    dConfig = {}

    dConfig['containerImage'] = 'musebuilder'
    dConfig['containerPath'] = '/data/builder'

    dConfig['debug'] = False

    dConfig['elasticsearch'] = True
    dConfig['es-instance-locs'] = ['muse1-int','muse2-int','muse3-int']
    
    #dConfig['es-file-index-name'] = 'muse-corpus-source'
    dConfig['es-file-index-name'] = 'muse-corpus-build'
    dConfig['es-file-index-type'] = 'muse-project-build'

    dConfig['forks'] = 5

    dConfig['hostname'] = socket.gethostname().replace('.','')

    dConfig['mysql-db'] = 'muse'
    dConfig['mysql-user'] = 'muse'
    dConfig['mysql-passwd'] = 'muse'
    dConfig['mysql-loc'] = 'muse2-int' 
    dConfig['mysql-port'] = 54321 
    dConfig['mysql'] = True

    dConfig['rebuild'] = False

    dConfig['redis-already-built'] = 'muse-already-built-'
    dConfig['redis-queue-to-build'] = 'muse-to-build'
    dConfig['redis-queue-building'] = 'muse-building'
    dConfig['redis-loc'] = 'muse2-int'
    dConfig['redis-port'] = '12345'
    dConfig['redis'] = True

    dArgs = {}

    # number of attempts with each to build targets to resolve dependencies
    dArgs['buildCycles'] = 2
    dArgs['containerMem'] = '2g'

    dArgs['buildScripts'] = {}
    dArgs['buildScripts']['root'] = '/managed/scripts'
    dArgs['buildScripts']['loader'] = os.path.join( dArgs['buildScripts']['root'], 'runBuild.sh' )
    dArgs['buildScripts']['cmakeBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'cmake.sh' )
    dArgs['buildScripts']['configureBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configure.sh' )
    dArgs['buildScripts']['configureacBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configureac.sh' )
    dArgs['buildScripts']['configureinBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configurein.sh' )
    dArgs['buildScripts']['makefileBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'make.sh' )

    dArgs['containerScripts'] = {}
    dArgs['containerScripts']['root'] = '/scripts'
    dArgs['containerScripts']['cmakeBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'cmake.sh' )
    dArgs['containerScripts']['configureBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'configure.sh' )
    dArgs['containerScripts']['configureacBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'configureac.sh' )
    dArgs['containerScripts']['configureinBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'configurein.sh' )
    dArgs['containerScripts']['makefileBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'make.sh' )

    dArgs['containerDirs'] = ['buildArtifacts', 'output', 'scripts', 'source']
    dArgs['containerOS'] = 'ubuntu14'
    dArgs['containerPath'] = dConfig['containerPath']

    dArgs['imageName'] = dConfig['containerImage'] + '-' + dArgs['containerOS']

    dArgs['script-name'] = 'build.sh'
    
    '''
    dArgs['build-targets'] = {
        'configure' : 'configureBuildType',
        'configure.ac' : 'configureacBuildType',
        'configure.in' : 'configureinBuildType',
        'CMakeLists.txt' : 'cmakeBuildType',
        'Makefile' : 'makefileBuildType'
        #'build.xml' : 'antBuildType', 
        #'pom.xml' : 'mavenBuildType'
    }
    '''

    dArgs['source-compilers'] = {
        'cBuildType' : 'gcc',
        'cppBuildType' : 'g++'
    }

    '''
    dArgs['source-targets'] = {
        '.c' : 'cBuildType',
        '.cc' : 'cppBuildType',
        '.cpp' : 'cppBuildType',
        '.cxx' : 'cppBuildType',
        '.c++' : 'cppBuildType'
    }
    '''

    ### command line argument handling
#    options, remainder = getopt.getopt(sys.argv[1:], 'f:o:rd', ['forks=','os=','rebuild','debug'])

    debug('func: main()', 'dConfig:',json.dumps(dConfig,indent=4))

    # loop thru list of buildSummaries
    with open('/home/muse/buildSummaries.log', 'r') as input_file:
        for line in input_file:
            debug(line)
            json_data=open(line.strip())
            data = json.load(json_data)

    	    # call to update mysql based on build summary json of project
            postBuildStatusUpdates(dArgs, data, dConfig)



###
if __name__ == "__main__":
    main(sys.argv[1:])
