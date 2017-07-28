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
def postBuildStatusUpdates(dArgs, dBuffer, dConfig):

    dBuildArgs = {}

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])

    dBuildArgs['projectName'] = dArgs['projectName']
    dBuildArgs['projectPath'] = dArgs['projectPath']
    dBuildArgs['buildTarPath'] = os.path.join( dArgs['buildPath'], dArgs['tarName'] )
    dBuildArgs['targets'] = dArgs['targets']
    dBuildArgs['builder'] = dArgs['containerName']
    dBuildArgs['buildTime'] = dBuffer['buildTime']
    dBuildArgs['version'] = dArgs['version']
    dBuildArgs['os'] = dArgs['containerOS']
    dBuildArgs['numObjectsPreBuild'] = dBuffer['numObjectsPreBuild']
    dBuildArgs['numObjectsPostBuild'] = dBuffer['numObjectsPostBuild']
    dBuildArgs['numObjectsGenerated'] = dBuffer['numObjectsGenerated']
    dBuildArgs['numSources'] = dBuffer['numSources']
    dBuildArgs['returnCode'] = dBuffer['returnCode']

    if dConfig['debug']: debug( 'func: postBuildStatusUpdates() build args prepared for mysql ingestion')

    # commit status to database
    dMp.open()
    dMp.insertIntoBuildStatusTargets(dArgs=dBuildArgs, bDebug=dConfig['debug'])
    dMp.insertIntoBuildStatus(dArgs=dBuildArgs, bDebug=dConfig['debug'])
    dMp.close()

    if dConfig['debug']: debug( 'func: postBuildStatusUpdates() build status ingested into mysql')

###
def isInt(s):

    try:

        i = int(s)

    except Exception, e:

        return False

    return True

###
#
###
def verifyEncoding(sOriginal, bDecode=True, bEncode=False):

    sTransformed = ''

    try:

        if bEncode: sTransformed = sOriginal.encode('utf-8')
        elif bDecode: sTransformed = sOriginal.decode('utf-8')

    except (ValueError, UnicodeDecodeError, UnicodeEncodeError) as e:

        try:

            if bEncode: sTransformed = sOriginal.encode('latin-1')
            elif bDecode: sTransformed = sOriginal.decode('latin-1')

        except (ValueError, UnicodeDecodeError, UnicodeEncodeError) as e:

            try:

                if bEncode: sTransformed = sOriginal.encode('utf-16')
                elif bDecode: sTransformed = sOriginal.decode('utf-16')

            except (ValueError, UnicodeDecodeError, UnicodeEncodeError) as e:

                warning('func verifyEncoding(): failed to transform sOriginal:', sOriginal, 'with utf-8, latin-1 and utf-16',e)
                traceback.print_exc()
                sTransformed = ''

    return sTransformed

###
def parseBuildOutput(dArgs, bDebug=False):

    dFiles = { 
        'buildTime' : 'runtime.log', 
        'numObjectsPreBuild' : 'numObjectsPreBuild.log',
        'numObjectsPostBuild' : 'numObjectsPostBuild.log',
        'numObjectsGenerated' : 'numObjectsGenerated.log',
        'numSources' : 'numSources.log'
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
            warning( 'func: parseBuildOutput() sFileType: ', sFileType,' missing for project:', dArgs['projectName'], 'container:', dArgs['containerName'] )

    dBuffer['targets'] = []

    dTargetSpecificFiles = {
        'returnCode' : 'retcode.log'#, 
        #'stdout' : 'stdout.log',
        #'stderr' : 'stderr.log'
    }

    iCtr = 0
    lRetCodes = []

    for dTarget in dArgs['targets']:

        for sFileType, sFileName in dTargetSpecificFiles.iteritems():

            sFileName = os.path.join( dArgs['dirs']['output'], sFileName + '.' + str(iCtr) )

            if os.path.isfile(sFileName):

                dTarget[sFileType] = ''

                with open(sFileName, 'r') as fBuilderFile:

                    # get file input and trim unnecessary whitespace before/after
                    dTarget[sFileType] = ( fBuilderFile.read() ).strip()
                    
                    '''
                    for sLine in fBuilderFile:
    
                        dTarget[sFileType] += verifyEncoding(sLine) + '\n'
                    '''

        if 'returnCode' in dTarget and isInt(dTarget['returnCode']):

            lRetCodes.append( int( dTarget['returnCode'].strip() ) )

        else: 

            warning( 'func: parseBuildOutput() invalid return code encountered:', json.dumps(dTarget, indent=4), 'project:', dArgs['projectName'], 'container:', dArgs['containerName'] )
            dTarget['returnCode'] = 666
            lRetCodes.append(666)

        dBuffer['targets'].append(dTarget)

        iCtr += 1

    if len(lRetCodes) > 0:
        dBuffer['returnCode'] = str( max(lRetCodes) )
    else:
        dBuffer['returnCode'] = '666'

    if bDebug:

        debug( 'func: parseBuildOutput() dBuffer:', json.dumps(dBuffer, indent=4) )

    return dBuffer

###
# starts build in docker container
###
def startBuild(dArgs, bDebug=False):

    #time.sleep( int(dArgs['containerId']) )

    sCmd = 'docker run -d -m=' + dArgs['containerMem'] + ' --cpuset-cpus=' + dArgs['containerId']
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

    # enter mutex protected region
    lock.acquire()

    os.system(sCmd)

    # sleep for 2 seconds in protected region to serialize calls to docker daemon
    time.sleep(2)

    # exit mutex protected region
    lock.release()

###
# get console logs from docker container
###
def getBuildLogs(dArgs, bDebug=False):

    #time.sleep( int(dArgs['containerId']) )

    sCmd = 'docker logs ' + dArgs['containerName'] + ' > ' + os.path.join(dArgs['dirs']['output'], 'run.out')

    # enter mutex protected region
    lock.acquire()

    os.system(sCmd)

    # sleep for 2 seconds in protected region to serialize calls to docker daemon
    time.sleep(2)

    # exit mutex protected region
    lock.release()

###
# remove container post build
###
def removeContainer(dArgs, bDebug=False):

    sCmd = 'docker rm ' + dArgs['containerName']

    if bDebug: debug('func: removeContainer() removing container post build:', sCmd)

    # enter mutex protected region
    lock.acquire()

    os.system(sCmd)

    # sleep for 2 seconds in protected region to serialize calls to docker daemon
    time.sleep(2)

    # exit mutex protected region
    lock.release()

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

    #sCmd = 'rsync -a ' + dArgs['projectPath'] + ' ' + dArgs['dirs']['source'] + '/'
    sCmd = 'tar xzf ' + dArgs['projectPath'] + ' --exclude=\'.git\' --exclude=\'.svn\'  -C ' + dArgs['dirs']['source'] + '/'

    debug('func: copySource() unpack source for container:', sCmd)
    if bDebug: debug('func: copySource() unpack source for container:', sCmd)

    os.system(sCmd)

###
# copy build-specific scripts locally for container
###
def copyScripts(dArgs, bDebug):

    sCmd = ''

    for dTarget in dArgs['targets']:

        if dTarget['buildType'] not in dArgs['source-compilers'].keys():

            sCmd = 'rsync -a ' + dArgs['buildScripts'][ dTarget['buildType'] ] + ' ' + dArgs['dirs']['scripts'] + '/ && '
    
    sCmd += 'rsync -a ' + dArgs['buildScripts']['loader'] + ' ' + dArgs['dirs']['scripts'] + '/'

    if bDebug: debug('func: copyScripts() copy script for container:', sCmd)

    os.system(sCmd)

###
# create build plan script for multi-target building
###
def createBuildPlanScript(dArgs, bDebug):

    sBuildPlan = ''

    # write script header

    sBuildPlan += '#!/bin/bash'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    sBuildPlan += '# zombie cleaner'
    sBuildPlan += '\n'
    sBuildPlan += '\n'
    sBuildPlan += 'function cleanup()'
    sBuildPlan += '\n'
    sBuildPlan += '{'
    sBuildPlan += '\n'
    sBuildPlan += '\tlocal pids=`jobs -p`'
    sBuildPlan += '\n'
    sBuildPlan += '\tif [[ "$pids" != "" ]]; then'
    sBuildPlan += '\n'
    sBuildPlan += '\t\tkill $pids >/dev/null 2>/dev/null'
    sBuildPlan += '\n'
    sBuildPlan += '\tfi'
    sBuildPlan += '\n'
    sBuildPlan += '\n'
    sBuildPlan += '\tsleep 5'
    sBuildPlan += '\n'
    sBuildPlan += '\n'
    sBuildPlan += '\tlocal pids=`jobs -p`'
    sBuildPlan += '\n'
    sBuildPlan += '\tif [[ "$pids" != "" ]]; then'
    sBuildPlan += '\n'
    sBuildPlan += '\t\tkill -9 $pids >/dev/null 2>/dev/null'
    sBuildPlan += '\n'
    sBuildPlan += '\tfi'
    sBuildPlan += '\n'
    sBuildPlan += '\n'
    sBuildPlan += '\tsleep 5'
    sBuildPlan += '\n'
    sBuildPlan += '}'
    sBuildPlan += '\n'
    sBuildPlan += '\n'
    sBuildPlan += 'trap cleanup EXIT'
    sBuildPlan += '\n'
    sBuildPlan += '\n'
    sBuildPlan += '### script payload'
    sBuildPlan += '\n'
    sBuildPlan += '\n'
    sBuildPlan += 'startTime=`date +%s`'
    sBuildPlan += '\n'
    sBuildPlan += '\n'
    sBuildPlan += 'touch /output/start.txt'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    # get pre-build object count
    sBuildPlan += 'find /source/ -type f -name "*.o" >> /output/objectsPreBuild.log'
    sBuildPlan += '\n'
    sBuildPlan += 'wc -l < /output/objectsPreBuild.log > /output/numObjectsPreBuild.log'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    # loop over targets

    for iBuildCycle in range (0, dArgs['buildCycles']):

        iCtr = 0

        for dTarget in dArgs['targets']:

            (sTargetRelativePath, sTargetName) = os.path.split(dTarget['buildTargetPath'])

            sBuildPlan += '\n'
            sBuildPlan += '################################################'
            sBuildPlan += '\n'
            sBuildPlan += '### build target: ' + dTarget['buildTargetPath'] + '  build cycle: ' + str(iBuildCycle) + ' ###'
            sBuildPlan += '\n'
            
            sBuildPlan += 'cd /source'
            sBuildPlan += '\n'
           
	    # Remove tarball from front of relative path
            sBuildPlan += 'cd "' + sTargetRelativePath + '"'
            sBuildPlan += '\n'
            
            if dTarget['buildType'] in dArgs['source-compilers'].keys():

                # source target
                
                # get source filename without extension for object file naming
                (sSourceFileName, _) = os.path.splitext(sTargetName)

                sBuildPlan += dArgs['source-compilers'][ dTarget['buildType'] ] + ' ' + sTargetName + ' -o ' + sSourceFileName + '.o > /output/stdout.log.' + str(iCtr) + ' 2> /output/stderr.log.' + str(iCtr)
                sBuildPlan += '\n'

            else:

                # build target
                sBuildPlan += dArgs['containerScripts'][ dTarget['buildType'] ] + ' > /output/stdout.log.' + str(iCtr) + ' 2> /output/stderr.log.' + str(iCtr)
                sBuildPlan += '\n'

            sBuildPlan += 'ret=$?'
            sBuildPlan += '\n'
            
            sBuildPlan += 'echo "$ret" > /output/retcode.log.' + str(iCtr)
            sBuildPlan += '\n'
            sBuildPlan += '################################################'
            sBuildPlan += '\n'

            iCtr += 1

    # write script footer

    sBuildPlan += '\n'
    sBuildPlan += '\n'

    sBuildPlan += 'endTime=`date +%s`'
    sBuildPlan += '\n'

    sBuildPlan += 'runTime=$(( endTime - startTime ))'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    sBuildPlan += 'for foundFile in `find / -type f -newer /output/start.txt -print -o -path \'/dev\' -prune -o -path \'/etc\' -prune -o -path \'/proc\' -prune -o -path \'/sys\' -prune -o -path \'/tmp\' -prune -o -path \'/usr\' -prune -o -path \'/var\' -prune`; do rsync -aR $foundFile /buildArtifacts/; done'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    # make sure to grab all object files whether we generated them in the container or not
    sBuildPlan += 'find /source -type f -name "*.o" -exec rsync -aR \'{}\' /buildArtifacts/ \;'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    # get post-build object count
    sBuildPlan += 'find /source/ -type f -name "*.o" >> /output/objectsPostBuild.log'
    sBuildPlan += '\n'
    sBuildPlan += 'wc -l < /output/objectsPostBuild.log > /output/numObjectsPostBuild.log'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    # generated object count
    sBuildPlan += 'find /source/ -type f -newer /output/start.txt -name "*.o" >> /output/objectsGenerated.log'
    sBuildPlan += '\n'
    sBuildPlan += 'wc -l < /output/objectsGenerated.log > /output/numObjectsGenerated.log'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    # get script run time
    sBuildPlan += 'echo $runTime > /output/runtime.log'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    # get number of source files
    for sSourceType in ['*.c','*.cxx','*.cpp','*.c++','*.cc']:

        sBuildPlan += 'find /source/ -type f -name "' + sSourceType + '" >> /output/sources.log'
        sBuildPlan += '\n'
        sBuildPlan += '\n'

    sBuildPlan += 'wc -l < /output/sources.log > /output/numSources.log'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    sBuildPlan += 'dmesg > /output/dmesg.log'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    sBuildPlan += 'touch /output/done.txt'
    sBuildPlan += '\n'
    sBuildPlan += '\n'

    if bDebug: debug('func: createBuildPlanScript() build plan contents:', sBuildPlan)

    # write out build plan
    with open( os.path.join(dArgs['dirs']['scripts'], 'runBuild.sh'), 'w' ) as fBuildPlan:

        try:

            fBuildPlan.write( verifyEncoding(sOriginal=sBuildPlan, bDecode=False, bEncode=True) )

        except (UnicodeDecodeError, UnicodeEncodeError) as e:

            traceback.print_exc()
            # warning('problem with encoding of build plan:', sBuildPlan)
            raise e

    sCmd = 'chmod u+x ' + os.path.join(dArgs['dirs']['scripts'], 'runBuild.sh')
    
    if bDebug: debug('func: createBuildPlanScript() making sure build plan is executable:', sCmd)

    os.system(sCmd)

###
# check on build -- returns True if still building and False if build is complete
###

def pollBuild(dArgs, bDebug=False):

    sStatus = ''
    bStatus = False

    # enter mutex protected region
    lock.acquire()

    sDockerStatus = subprocess.check_output(['docker', 'ps', '-a'])

    # sleep for 2 seconds in protected region to serialize calls to docker daemon
    time.sleep(2)

    # exit mutex protected region
    lock.release()
    
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
    sCmd = 'cd ' + dArgs['containerPath'] + ' && tar -zcf ' +  dArgs['tarName'] + ' ' + dArgs['containerName'] + ' && '

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

    try:

        (iContainerId, dArgs, dConfig) = tTup

        # dual queues -- primary for getting what project to build next, secondary to mark what is being built
        qRedis = RedisQueue(name=dConfig['redis-queue-to-build'], name2=dConfig['redis-queue-building'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

        # set of existing builds for this os container used to prune out projects already built with this container
        sExistingBuilds = RedisSet(name=dConfig['redis-already-built-nate'], namespace='set', host=dConfig['redis-loc'], port=dConfig['redis-port'])

        debug('func: processBuildTargets(), has ' + str( len(sExistingBuilds) ) + ' built projects') 
        iCtr = 0

        while 1:

            sBuildTarget = qRedis.getnpush(block=True, timeout=30)
            #sBuildTarget = qRedis.peek()

            # debug(sBuildTarget)

            if sBuildTarget:

                if dConfig['debug']: debug('func: processBuildTargets() sBuildTarget:', sBuildTarget)

                dBuildTarget = json.loads(sBuildTarget)

                # initial setup

                dArgs['projectName'] = dBuildTarget['projectName']

                if dArgs['projectName'] in sExistingBuilds:

                    warning('func: processBuildTargets() project:', dArgs['projectName'], ' already built... skipping...')
                    continue

                #sProjectPath = os.path.relpath(dBuildTarget['projectPath'], '/data/corpus')
                #sProjectPath = os.path.join('/nfsbuild/nfsbuild', sProjectPath)

                #dArgs['buildPath'] = sProjectPath
                dArgs['targets'] = dBuildTarget['targets']

                if dConfig['debug']: debug( 'func: processBuildTargets() targets:', json.dumps(dArgs['targets'],indent=4))

                dArgs['containerId'] = str(iContainerId)
                dArgs['containerName'] = dConfig['containerImage'] + '-' + dArgs['containerOS'] + '-' + dConfig['hostname'] + '_' + str(iContainerId)

                dArgs['dirs'] = {}
                dArgs['dirs']['root'] = os.path.join( dConfig['containerPath'], dArgs['containerName'] )

                for sDir in dArgs['containerDirs']:
                
                    dArgs['dirs'][sDir] = os.path.join( dArgs['dirs']['root'], sDir )

                # /data/corpus on muse2 is mounted under /nfscorpus/nfscorpus on all 3 servers (via mount-bind on muse2 and NFS on muse1 and muse3)
                debug( 'projectPath: ', dBuildTarget['projectPath'])
                if "_8tof" in dBuildTarget['projectPath']:
                    sProjectPath = os.path.relpath(dBuildTarget['projectPath'], '/data/corpus_8tof')
                    sBuildPath = os.path.join('/data/builder_SAN/fedora21', sProjectPath)
                    sProjectPath = os.path.join('/data/corpus_8tof', sProjectPath)
                if "_0to7" in dBuildTarget['projectPath']:
                    sProjectPath = os.path.relpath(dBuildTarget['projectPath'], '/data/corpus_0to7')
                    sBuildPath = os.path.join('/data/builder_SAN/fedora21', sProjectPath)
                    sProjectPath = os.path.join('/data/corpus_0to7', sProjectPath)
                debug( 'projectPathDone: ', sProjectPath)

                dArgs['buildPath'] = sBuildPath

                '''
                # determine code root in project directory
                sCodePath = dBuildTarget['buildTargetPath']
                if sCodePath.startswith('./'):
                    sCodePath = dBuildTarget['buildTargetPath'][2:]
                sCodeRoot = sCodePath[:sCodePath.index(os.sep)] if os.sep in sCodePath else sCodePath
                '''
		plist = sProjectPath.split('/')
		uuid=plist[len(plist)-1]
                tar=uuid + ("_code.tgz")
                debug( 'tarball: ', tar)
                
                dArgs['projectPath'] = os.path.join(sProjectPath, tar)

                # add code root to project path
#                if dBuildTarget['codeDir']:
#                    print('none')
                    #dArgs['projectPath'] = os.path.join(sProjectPath, dBuildTarget['codeDir'])

#                else:

#                   warning('func: processBuildTargets() encountered project:', dBuildTarget['projectName'], ' with empty or NULL codeDir which is not supported. Project build skipped...')
#                    continue

                sTimeStamp = datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
                dArgs['jsonName'] = 'build-' + sTimeStamp + '.json'
                dArgs['tarName'] = dArgs['projectName'] + '-' + sTimeStamp + '.tgz'
                dArgs['version'] = dBuildTarget['version']

                # setup container
                makeDirs(dArgs=dArgs, bDebug=dConfig['debug'])
                copySource(dArgs=dArgs, bDebug=dConfig['debug'])
                copyScripts(dArgs=dArgs, bDebug=dConfig['debug'])
                createBuildPlanScript(dArgs=dArgs, bDebug=dConfig['debug'])
                recordProjectName(dArgs=dArgs, bDebug=dConfig['debug'])
                startBuild(dArgs=dArgs, bDebug=dConfig['debug'])

                # sleep until build completes
                while pollBuild(dArgs=dArgs, bDebug=dConfig['debug']):

                    if dConfig['debug']: debug( 'func: processBuildTargets() build not completed... sleeping')
                    time.sleep(10)

                # get container logs
                getBuildLogs(dArgs=dArgs, bDebug=dConfig['debug'])

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

                if dConfig['debug'] and iCtr >= 1:

                    break

            else:

                break

        if dConfig['debug']: 

            debug( 'func: processBuildTargets() sBuildTarget is either empty or none, likely since the redis queue is empty')
            debug( 'func: processBuildTargets() redis queue size:', qRedis.size())
            debug( 'func: processBuildTargets() exiting...')

    except Exception as e:

        warning('Caught exception in worker thread:', iContainerId)
        traceback.print_exc()
        raise e

###
def loadExistingBuilds(dConfig, sOS):

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])
    dMp.open()

    sExistingBuilds = RedisSet(name=dConfig['redis-already-built'], namespace='set', host=dConfig['redis-loc'], port=dConfig['redis-port'])
    sExistingBuilds.flush()

    lProjectRows = dMp.select(sSelectClause='projectName', sTable='builtWith_' + sOS, bDebug=dConfig['debug'])

    dMp.close()

#    for tProjectRow in lProjectRows:

#        (sProjectName, ) = tProjectRow
#        sExistingBuilds.put(sProjectName)

    debug('func: loadRebuildSet()', sOS + ' has ' + str( len(sExistingBuilds) ) + ' built projects') 
    #if dConfig['debug']: debug('func: loadRebuildSet()', sOS + ' has ' + str( len(sExistingBuilds) ) + ' built projects') 

###
def usage():

    warning('Usage: buildProjectsByType.py --queue-projects=\"configure.ac\" --os=\"ubuntu14" --rebuild --debug')

###
def main(argv):

    # defaults
    bError = False

    dConfig = {}

    dConfig['containerImage'] = 'musebuilder'
    #dConfig['containerPath'] = '/data/builder'
    dConfig['containerPath'] = '/data/builder_SAN/containers'

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

    dConfig['rebuild'] = False

    dConfig['redis-already-built'] = 'muse-already-built-'
    dConfig['redis-already-built-nate'] = 'NEWbuiltProjects'
    dConfig['redis-queue-to-build'] = 'muse-to-build'
    dConfig['redis-queue-building'] = 'muse-building'
    dConfig['redis-loc'] = 'muse2-int'
    # dConfig['redis-port'] = '6379'
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

    lSupportedOSs = ['fedora20', 'fedora21', 'ubuntu12', 'ubuntu14']

    ### command line argument handling
    options, remainder = getopt.getopt(sys.argv[1:], 'f:o:rd', ['forks=','os=','rebuild','debug'])

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
       
        elif opt in ('-r', '--rebuild'):

            dConfig['rebuild'] = True
       
        elif opt in ('-d', '--debug'):

            dConfig['debug'] = True

    debug('func: main()', 'dConfig:',json.dumps(dConfig,indent=4))

    if bError: usage()
    else:

        '''
        # pre-initialization -- if projects remained in building queue, put them back in queue-to-build
        qToBuildRedis = RedisQueue(name=dConfig['redis-queue-building'], name2=dConfig['redis-queue-to-build'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

        for iCtr in range(0, len(qToBuildRedis)):

            qToBuildRedis.getnpush()
        '''

        dConfig['redis-already-built'] = dConfig['redis-already-built'] + dArgs['containerOS']

        sExistingBuilds = RedisSet(name=dConfig['redis-already-built'], namespace='set', host=dConfig['redis-loc'], port=dConfig['redis-port'])
        sExistingBuilds.flush()
        
        if not dConfig['rebuild']: 
   
            loadExistingBuilds(dConfig, dArgs['containerOS'])

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
        print(lConsumerArgs)
 
        oConsumerPool.map(processBuildTargets, lConsumerArgs)

        oConsumerPool.close()
        oConsumerPool.join()
        
        # processBuildTargets( (0, dArgs, dConfig) ) 

        if dConfig['debug']: debug('func: main()', "all processes completed") 

        iEnd = time.time()

        printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
