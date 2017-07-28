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
#from redisHelper import RedisSet

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
def postBuildStatusUpdates(dArgs, dBuffer, dConfig):

    dBuildArgs = {}

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])

    lBuildTypes = dMp.getBuildTypes()
    for sBuildType in lBuildTypes:

        dBuildArgs[sBuildType] = False

    dBuildArgs['projectName'] = dArgs['projectName']
    dBuildArgs['projectPath'] = dArgs['projectPath']
    dBuildArgs['buildTarPath'] = os.path.join( dArgs['buildPath'], dArgs['tarName'] )
    dBuildArgs['buildTargetPath'] = dArgs['buildTargetPath']
    dBuildArgs['builder'] = dArgs['containerName']
    dBuildArgs['buildTime'] = dBuffer['buildTime']
    #dBuildArgs['dmesg'] = dBuffer['dmesg']
    dBuildArgs['version'] = dArgs['version']
    dBuildArgs['os'] = dArgs['containerOS']
    dBuildArgs['numObjects'] = dBuffer['numObjects']
    dBuildArgs['returnCode'] = dBuffer['returnCode']
    ### troubleshoot serialization error
    #dBuildArgs['stdout'] = dBuffer['stdout']
    #dBuildArgs['stderr'] = dBuffer['stderr']

    dBuildArgs[ dArgs['buildType'] ] = True

    if dConfig['debug']: debug( 'func: postBuildStatusUpdates() build args prepared for es and mysql ingestion')

    # commit status to elasticsearch

    oES = Elasticsearch(dConfig['es-instance-locs'])
    oES.index(index=dConfig['es-file-index-name'],doc_type=dConfig['es-file-index-type'],body=dBuildArgs, timeout="20m", request_timeout=600.)

    if dConfig['debug']: debug( 'func: postBuildStatusUpdates() build status ingested into es')

    # commit status to database
    dMp.open()
    dMp.insertIntoBuildStatus(dArgs=dBuildArgs, bDebug=dConfig['debug'])
    dMp.close()

    if dConfig['debug']: debug( 'func: postBuildStatusUpdates() build status ingested into mysql')

###
def parseBuildOutput(dArgs, bDebug=False):

    dFiles = {
        'returnCode' : 'retcode.log', 
        'buildTime' : 'runtime.log', 
        #'dmesg' : 'dmesg.log',
        #'stdout' : 'stdout.log',
        #'stderr' : 'stderr.log',
        'numObjects' : 'numObjects.log'
    }

    dBuffer = {}

    for sFileType, sFileName in dFiles.iteritems():

        sFileName = os.path.join( dArgs['dirs']['output'], sFileName)

        if os.path.isfile(sFileName):

            with open(sFileName, 'r') as fBuilderFile:

                # get file input and trim unnecessary whitespace before/after
                dBuffer[sFileType] = ( fBuilderFile.read() ).strip()

        else:

            dBuffer[sFileType] = ''

    if bDebug:

        debug( 'func: parseBuildOutput() dBuffer:', json.dumps(dBuffer, indent=4) )

    return dBuffer

###
# starts build in docker container
###
def startBuild(dArgs, bDebug=False):

    #time.sleep( int(dArgs['containerId']) )

    sCmd = 'docker run -d -m=4g --cpuset-cpus=' + dArgs['containerId']
    sCmd += ' --name ' + dArgs['containerName']
    sCmd += ' --ulimit nproc=2048:4096'

    '''
    VOLUME ["/buildArtifacts"]
    VOLUME ["/output"]
    VOLUME ["/scripts"]
    VOLUME ["/source"]
    '''

    sCmd += ' -v ' + dArgs['dirs']['buildArtifacts'] + ':/buildArtifacts'
    sCmd += ' -v ' + dArgs['dirs']['output'] + ':/output'
    sCmd += ' -v ' + dArgs['dirs']['scripts'] + ':/scripts'
    sCmd += ' -v ' + dArgs['dirs']['source'] + ':/source'
    sCmd += ' ' + dArgs['imageName']
    sCmd += ' /scripts/runBuild.sh'

    if bDebug: debug('func: startBuild() starting container:', sCmd)

    '''
    use locking semaphore for mutex
    noticing weird docker container spawning issues when containers are started simulateneously by multiple processes
    '''
    lock.acquire()

    # enter mutex protected region

    os.system(sCmd)

    # sleep for 2 seconds in protected region to ensure docker run is successfully started in serialized fashion
    time.sleep(2)

    # exit mutex protected region

    lock.release()

###
# remove container post build
###
def removeContainer(dArgs, bDebug=False):

    sCmd = 'docker rm ' + dArgs['containerName']

    if bDebug: debug('func: removeContainer() removing container post build:', sCmd)

    os.system(sCmd)

###
# make container directories
###
def makeDirs(dArgs, bDebug=False):

    lCmds = []

    # initialize -- ensure old container directories aren't there
    # remove container directory
    sCmd = 'rm -rf ' + os.path.join(dArgs['containerPath'], dArgs['containerName'])
    lCmds.append(sCmd)

    for sDirKey, sDirName in dArgs['dirs'].iteritems():

        lCmds.append('mkdir -p ' + sDirName)

    if bDebug: debug('func: makeDirs() making dirs for container:', json.dumps(lCmds, indent=4))

    for sCmd in lCmds:

        os.system(sCmd)

###
# copy source locally for container
###
def copySource(dArgs, bDebug=False):

    sCmd = 'rsync -a ' + dArgs['projectPath'] + '/ ' + dArgs['dirs']['source'] + '/'

    if bDebug: debug('func: copySource() copy source for container:', sCmd)

    os.system(sCmd)

###
# copy build-specific script locally for container
###
def copyScripts(dArgs, bDebug):

    sCmd = 'rsync -a ' + dArgs['buildScripts'][ dArgs['buildType'] ] + ' ' + dArgs['dirs']['scripts'] + '/' + dArgs['script-name'] + ' && '
    sCmd += 'rsync -a ' + dArgs['buildScripts']['loader'] + ' ' + dArgs['dirs']['scripts'] + '/'

    if bDebug: debug('func: copyScripts() copy script for container:', sCmd)

    os.system(sCmd)

###
# check on build -- returns True if still building and False if build is complete
###

def pollBuild(dArgs, bDebug=False):

    sStatus = ''
    bStatus = False

    sDockerStatus = subprocess.check_output(['docker', 'ps', '-a'])
    
    if bDebug: debug('func: startBuild() docker ps -a output:\n', sDockerStatus)

    for sLine in sDockerStatus.split('\n'):

        if bDebug: debug('func: startBuild() parsed docker ps -a output:', sLine)

        if dArgs['containerName'] in sLine:

            sStatus = sLine

    if bDebug: debug('func: pollBuild() container building status:', sStatus)

    if 'Exited (' not in sStatus:

        bStatus = True

    if bDebug: debug('func: pollBuild() container building:', bStatus)

    return bStatus

###
# tar up container directories
###
def tarUpContainerDirs(dArgs, bDebug=False):

    # tar up container directory
    sCmd = 'cd ' + dArgs['containerPath'] + ' && tar -zcvf ' +  dArgs['tarName'] + ' ' + dArgs['containerName'] + ' && '

    # make project-specifc build directory if it does not exist
    sCmd += 'mkdir -p ' + dArgs['buildPath'] + ' && '

    # move tar to build directory
    sCmd += 'mv ' + os.path.join(dArgs['containerPath'], dArgs['tarName']) + ' ' + dArgs['buildPath'] + ' && '

    # remove container directory
    sCmd += 'rm -rf ' + os.path.join(dArgs['containerPath'], dArgs['containerName'])

    if bDebug: debug('func: tarUpContainerDirs() taring up container dirs:', sCmd)

    os.system(sCmd)

###
# record project name in container directories in case build/container troubleshooting is required
###
def recordProjectName(dArgs, bDebug=False):

    # tar up container directory
    sCmd = 'echo \"' + dArgs['projectName'] + '\" > ' + os.path.join(dArgs['dirs']['output'], 'projectName.log')

    if bDebug: debug('func: recordProjectName() recoding project name:', sCmd)

    os.system(sCmd)

###
# process build targets (type-specific) in redis queue
###
def processBuildTargets(tTup):

    (iContainerId, dArgs, dConfig) = tTup

    # dual queues -- primary for getting what project to build next, secondary to mark what is being built
    qRedis = RedisQueue(name=dConfig['redis-queue-to-build'], name2=dConfig['redis-queue-building'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    iCtr = 0

    while 1:

        sBuildTarget = qRedis.getnpush(block=True, timeout=30)
        #sBuildTarget = qRedis.peek()

        # debug(sBuildTarget)

        if sBuildTarget:

            if dConfig['debug']: debug( 'func: processBuildTargets() sBuildTarget:', sBuildTarget)

            dBuildTarget = json.loads(sBuildTarget)

            # initial setup

            sProjectPath = os.path.relpath(dBuildTarget['projectPath'], '/data/corpus')
            sProjectPath = os.path.join('/nfsbuild/nfsbuild', sProjectPath)

            dArgs['buildPath'] = sProjectPath
            dArgs['buildTargetPath'] = dBuildTarget['buildTargetPath']

            dArgs['buildType'] = dConfig['search-strings'][os.path.basename(dArgs['buildTargetPath'])]

            if dConfig['debug']: debug( 'func: processBuildTargets() dArgs[\'buildType\']:', dArgs['buildType'])

            dArgs['containerId'] = str(iContainerId)
            dArgs['containerName'] = dConfig['containerImage'] + '-' + dArgs['containerOS'] + '-' + dArgs['buildType'] + '-' + dConfig['hostname'] + '_' + str(iContainerId)

            dArgs['dirs'] = {}
            dArgs['dirs']['root'] = os.path.join( dConfig['containerPath'], dArgs['containerName'] )

            for sDir in dArgs['containerDirs']:
            
                dArgs['dirs'][sDir] = os.path.join( dArgs['dirs']['root'], sDir )

            dArgs['projectName'] = dBuildTarget['projectName']

            # /data/corpus on muse2 is mounted under /nfscorpus/nfscorpus on all 3 servers (via mount-bind on muse2 and NFS on muse1 and muse3)
            sProjectPath = os.path.relpath(dBuildTarget['projectPath'], '/data/corpus')
            sProjectPath = os.path.join('/nfscorpus/nfscorpus', sProjectPath)
            dArgs['projectPath'] = os.path.join(sProjectPath, 'latest')

            sTimeStamp = datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
            dArgs['tarName'] = dArgs['projectName'] + '-' + sTimeStamp + '.tgz'

            dArgs['version'] = dBuildTarget['version']

            # setup container
            makeDirs(dArgs=dArgs, bDebug=dConfig['debug'])
            copySource(dArgs=dArgs, bDebug=dConfig['debug'])
            copyScripts(dArgs=dArgs, bDebug=dConfig['debug'])
            recordProjectName(dArgs=dArgs, bDebug=dConfig['debug'])
            startBuild(dArgs=dArgs, bDebug=dConfig['debug'])

            # sleep until build completes
            while pollBuild(dArgs=dArgs, bDebug=dConfig['debug']):

                if dConfig['debug']: debug( 'func: processBuildTargets() build not completed... sleeping')
                time.sleep(10)

            # get build output
            dBuffer = parseBuildOutput(dArgs=dArgs, bDebug=dConfig['debug'])

            # index build output
            postBuildStatusUpdates(dArgs=dArgs, dBuffer=dBuffer, dConfig=dConfig)

            # archive build artifacts
            tarUpContainerDirs(dArgs=dArgs, bDebug=dConfig['debug'])

            # remove container
            removeContainer(dArgs=dArgs, bDebug=dConfig['debug'])

            # remove project from "building" queue
            # qRedis.done(value=sBuildTarget)

            iCtr += 1

            if dConfig['debug'] and iCtr >= 10:

                break

        else:

            break

    if dConfig['debug']: 

        debug( 'func: processBuildTargets() sBuildTarget is either empty or none, likely since the redis queue is empty')
        debug( 'func: processBuildTargets() redis queue size:', qRedis.size())
        debug( 'func: processBuildTargets() exiting...')

###
def usage():
    warning('Usage: buildProjectsByType.py --queue-projects=\"configure.ac\" --os=\"ubuntu14" --debug')

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
    #dConfig['es-instance-locs'] = ['muse2-int','muse3-int']
    #dConfig['es-instance-locs'] = ['muse3-int']
    
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

    dConfig['os'] = 'ubuntu14'

    dConfig['redis-queue-to-build'] = 'muse-to-build'
    dConfig['redis-queue-building'] = 'muse-building'
    dConfig['redis-loc'] = 'muse2-int'
    # dConfig['redis-port'] = '6379'
    dConfig['redis-port'] = '12345'
    dConfig['redis'] = True

    dConfig['search-strings'] = {
        'configure' : 'configureBuildType',
        'configure.ac' : 'configureacBuildType',
        'configure.in' : 'configureinBuildType',
        'CMakeLists.txt' : 'cmakeBuildType',
        'Makefile' : 'makefileBuildType'
        #'build.xml' : 'antBuildType', 
        #'pom.xml' : 'mavenBuildType'
    }

    dArgs = {}

    dArgs['buildScripts'] = {}
    dArgs['buildScripts']['root'] = '/managed/scripts'
    dArgs['buildScripts']['loader'] = os.path.join( dArgs['buildScripts']['root'], 'runBuild.sh' )
    dArgs['buildScripts']['cmakeBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'cmake.sh' )
    dArgs['buildScripts']['configureBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configure.sh' )
    dArgs['buildScripts']['configureacBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configureac.sh' )
    dArgs['buildScripts']['configureinBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configurein.sh' )
    dArgs['buildScripts']['makefileBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'make.sh' )

    dArgs['containerDirs'] = ['buildArtifacts', 'output', 'scripts', 'source']
    dArgs['containerOS'] = 'ubuntu14'
    dArgs['containerPath'] = dConfig['containerPath']

    dArgs['imageName'] = dConfig['containerImage'] + '-' + dArgs['containerOS']

    dArgs['script-name'] = 'build.sh'

    lSupportedOSs = ['ubuntu12', 'ubuntu14']

    ### command line argument handling
    options, remainder = getopt.getopt(sys.argv[1:], 'f:q:o:d', ['forks=','queue-projects=','os=','debug'])

    # debug('func: main()', 'options:', options)
    # debug('func: main()', 'remainder:', remainder)

    for opt, arg in options:

        if opt in ('-f', '--forks'):

            try:
            
                dConfig['forks'] = int(arg)

            except ValueError as e:

                bError = True

        elif opt in ('-o', '--os'):

            if arg in lSupportedOSs:

                dArgs['containerOS'] = arg
                dArgs['imageName'] = dConfig['containerImage'] + '-' + dArgs['containerOS']

            else:

                bError = True

        elif opt in ('-d', '--debug'):

            dConfig['debug'] = True

    if bError: usage()
    else:

        # pre-initialization -- if projects remained in building queue, put them back in queue-to-build
        qToBuildRedis = RedisQueue(name=dConfig['redis-queue-building'], name2=dConfig['redis-queue-to-build'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

        for iCtr in range(0, len(qToBuildRedis)):

            qToBuildRedis.getnpush()

        iStart = time.time()

        ### setup consumers
        
        lConsumerArgs = []

        # create a locking semaphore for mutex
        lock = multiprocessing.Lock()

        for iCtr in range(0, dConfig['forks']):

            lConsumerArgs.append( (iCtr, dArgs, dConfig) )

        # create pool of workers -- number of workers equals the number of search strings to be processed
        oConsumerPool = multiprocessing.Pool( processes=dConfig['forks'], initializer=initialize_lock, initargs=(lock,) )

        ### do work -- use pool of workers to search for each search string in muse-corpus-source es index
        oConsumerPool.map(processBuildTargets, lConsumerArgs)

        oConsumerPool.close()
        oConsumerPool.join()
        
        #processBuildTargets( (0, dArgs, dConfig) ) 

        if dConfig['debug']: debug('func: main()', "all processes completed") 

        iEnd = time.time()

        printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
