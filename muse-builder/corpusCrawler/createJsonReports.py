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

from locallibs import debug
from locallibs import printMsg
from locallibs import warning

from projectDB import MuseProjectDB

from redisHelper import RedisQueue
from redisHelper import RedisSet

###################


###
# producer process; gets builds from mysql and populates redis queue with build summaries
###
def createBuildSummaries(dConfig):

    qRedis = RedisQueue(dConfig['redis-queue-json'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    dMp = MuseProjectDB(db=dConfig['mysql-db'],port=dConfig['mysql-port'],user=dConfig['mysql-user'],passwd=dConfig['mysql-passwd'],loc=dConfig['mysql-loc'])

    sLimitClause = ''
    if dConfig['debug']: sLimitClause = '10'

    dReturnCodeLookup = {
        'buildSuccess': 'success',
        'buildPartial': 'partial',
        'buildFail': 'fail'
    }

    sSelectClause='projectName,projectPath,buildTarPath,buildTime,version,os,numObjectsPreBuild,numObjectsPostBuild,numObjectsGenerated,numSources,buildTargetPath,configureBuildType,configureacBuildType,configureinBuildType,cmakeBuildType,makefileBuildType,antBuildType,mavenBuildType,returnCode'

    lTargetTypes = ['configureBuildType','configureacBuildType','configureinBuildType','cmakeBuildType','makefileBuildType','antBuildType','mavenBuildType']

    dMp.open()

    iProjectCount = 0

    dProjects = {
        'success' : RedisSet(dConfig['redis-set'] + '-success', namespace='set', host=dConfig['redis-loc'], port=dConfig['redis-port']),
        'partial' : RedisSet(dConfig['redis-set'] + '-partial', namespace='set', host=dConfig['redis-loc'], port=dConfig['redis-port']),
        'fail' : RedisSet(dConfig['redis-set'] + '-fail', namespace='set', host=dConfig['redis-loc'], port=dConfig['redis-port'])
    }

    for sTable, sProjectBin in dReturnCodeLookup.iteritems():

        # empty redis set
        dProjects[sProjectBin].flush()

        lProjects = dMp.select(sSelectClause='projectName', sTable=sTable, sOrderByClause='projectName', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

        # populate redis set with projects of each bin type
        for tProject in lProjects:

            (sProjectName, ) = tProject

            dProjects[sProjectBin].put(sProjectName)

    dProjectSummary = {}

    lTargetRows = dMp.select(sSelectClause=sSelectClause, sTable='buildStatusWithTargets', sOrderByClause='projectName,buildTarPath', sLimitClause=sLimitClause, bDebug=dConfig['debug'])

    for tTargetRow in lTargetRows:

        dTarget = {}

        (dTarget['projectName'], dTarget['projectPath'], dTarget['buildTarPath'], dTarget['buildTime'], dTarget['version'], dTarget['os'], dTarget['numObjectsPreBuild'], dTarget['numObjectsPostBuild'], dTarget['numObjectsGenerated'], dTarget['numSources'], dTarget['buildTargetPath'], dTarget['configureBuildType'], dTarget['configureacBuildType'], dTarget['configureinBuildType'], dTarget['cmakeBuildType'], dTarget['makefileBuildType'], dTarget['antBuildType'], dTarget['mavenBuildType'], dTarget['returnCode']) = tTargetRow

        if dProjectSummary:

            if dProjectSummary['projectName'] == dTarget['projectName']:

                try:

                    (dBuild for dBuild in dProjectSummary['builds'] if dBuild['buildTarPath'] == dTarget['buildTarPath']).next()

                except (StopIteration) as e:

                    dBuild = {
                        'buildTarPath' : dTarget['buildTarPath'],
                        'buildTime' : dTarget['buildTime'],
                        'version' : dTarget['version'],
                        'os' : dTarget['os'],
                        'numObjectsPreBuild' : dTarget['numObjectsPreBuild'],
                        'numObjectsPostBuild' : dTarget['numObjectsPostBuild'],
                        'numObjectsGenerated' : dTarget['numObjectsGenerated'],
                        'numSources' : dTarget['numSources'],
                        'targets' : []
                    }

                    dProjectSummary['builds'].append(dBuild)

                dTargetSummary = {'buildTargetPath' : dTarget['buildTargetPath'], 'returnCode' : dTarget['returnCode']}

                for sTargetType in lTargetTypes:

                    if dTarget[sTargetType] == 1: 

                        dTargetSummary['target-type'] = sTargetType
                        break

                dBuild['targets'].append(dTargetSummary)

            else:

                if dConfig['debug']: debug( 'func: createBuildSummaries() dProjectSummary:', json.dumps(dProjectSummary,indent=4) )
                qRedis.put( json.dumps(dProjectSummary) )
                iProjectCount += 1
                dProjectSummary = {}

        if not dProjectSummary:

            # project specific build summary info

            dBuild = {
                'buildTarPath' : dTarget['buildTarPath'],
                'buildTime' : dTarget['buildTime'],
                'version' : dTarget['version'],
                'os' : dTarget['os'],
                'numObjectsPreBuild' : dTarget['numObjectsPreBuild'],
                'numObjectsPostBuild' : dTarget['numObjectsPostBuild'],
                'numObjectsGenerated' : dTarget['numObjectsGenerated'],
                'numSources' : dTarget['numSources'],
                'targets' : []
            }

            dProjectSummary = {
                'projectName' : dTarget['projectName'],
                'sourcePath' : dTarget['projectPath'],
                'builds' : [dBuild]
            }

            if dTarget['projectName'] in dProjects['success']: dProjectSummary['buildStatus'] = 'success'
            elif dTarget['projectName'] in dProjects['partial']: dProjectSummary['buildStatus'] = 'partial'
            elif dTarget['projectName'] in dProjects['fail']: dProjectSummary['buildStatus'] = 'fail'

            # target specific build summary info

            dTargetSummary = {'buildTargetPath' : dTarget['buildTargetPath'], 'returnCode' : dTarget['returnCode']}

            for sTargetType in lTargetTypes:

                if dTarget[sTargetType] == 1: 

                    dTargetSummary['target-type'] = sTargetType
                    break

            dBuild['targets'].append(dTargetSummary)

    if dProjectSummary:

        if dConfig['debug']: debug( 'func: createBuildSummaries() dProjectSummary:', json.dumps(dProjectSummary,indent=4) )
        qRedis.put( json.dumps(dProjectSummary) )
        iProjectCount += 1

        dProjectSummary = {}

    dMp.close()

    printMsg('func: createBuildSummaries()', str(iProjectCount), 'projects queued')

###
# consumer process; gets build summaries from redis queue and writes out summaries in project build directories
###
def writeBuildSummaries(dConfig):

    qRedis = RedisQueue(dConfig['redis-queue-json'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])

    while 1:

        # get next project summary to process
        sProjectSummary = qRedis.get(block=True, timeout=30)

        if sProjectSummary:

            # do something with summary
            dProjectSummary = json.loads(sProjectSummary)

            #sBuildPath = os.path.relpath(dProjectSummary['sourcePath'], '/nfscorpus/nfscorpus')
            #sBuildPath = os.path.join('/nfsbuild/nfsbuild', sBuildPath)
            if "_8tof" in dProjectSummary['sourcePath']:
                sBuildPath = os.path.relpath(dProjectSummary['sourcePath'], '/data/corpus_8tof')
                sBuildPath = os.path.join('/data/builder_SAN/outputCyber', sBuildPath)
            if "_0to7" in dProjectSummary['sourcePath']:
                sBuildPath = os.path.relpath(dProjectSummary['sourcePath'], '/data/corpus_0to7')
                sBuildPath = os.path.join('/data/builder_SAN/outputCyber', sBuildPath)


            (sBuildPath, _) = os.path.split(sBuildPath)

            # ensure build directory exists
            sCmd = 'mkdir -p ' + sBuildPath
            if dConfig['debug']: debug( 'func: writeBuildSummaries() mkdir cmd:', sCmd)

            os.system(sCmd)

            sJsonPath = os.path.join(sBuildPath, 'build.json')
            if dConfig['debug']: debug( 'func: writeBuildSummaries() sJsonPath:', sJsonPath)

            with open(sJsonPath, 'w' ) as fJson:

                fJson.write(json.dumps(dProjectSummary, indent=4))

        else:

            break

###
def usage():
    warning('Usage: createJsonReports.py --forks=5 --debug')

###
def main(argv):

    # defaults
    bError = False

    dConfig = {}

    dConfig['debug'] = False

    dConfig['forks'] = 5

    dConfig['mysql-db'] = 'muse'
    dConfig['mysql-user'] = 'muse'
    dConfig['mysql-passwd'] = 'muse'
    dConfig['mysql-loc'] = 'muse2-int' 
    dConfig['mysql-port'] = 54321 
    dConfig['mysql'] = True

    dConfig['redis-queue-json'] = 'muse-json'
    dConfig['redis-set'] = 'muse-projects'
    dConfig['redis-loc'] = 'muse2-int'
    # dConfig['redis-port'] = '6379'
    dConfig['redis-port'] = '12345'
    dConfig['redis'] = True

    ### command line argument handling
    options, remainder = getopt.getopt(sys.argv[1:], 'f:d', ['forks=','debug'])

    # debug('func: main()', 'options:', options)
    # debug('func: main()', 'remainder:', remainder)

    for opt, arg in options:

        if opt in ('-f', '--forks'):

            try:
            
                dConfig['forks'] = int(arg)

            except ValueError as e:

                bError = True

        elif opt in ('-d', '--debug'):

            dConfig['debug'] = True

    debug('func: main()', 'dConfig:',json.dumps(dConfig,indent=4))

    if bError: usage()
    else:

        iStart = time.time()

        # prepare redis queue for producer, flush queue before starting the producer
        qRedis = RedisQueue(dConfig['redis-queue-json'], namespace='queue', host=dConfig['redis-loc'], port=dConfig['redis-port'])
        qRedis.flush()

        '''
        # multi-process approach
        # call producer process that populates redis queue with project path roots
        pProducer = multiprocessing.Process( target=createBuildSummaries, args=(dConfig) )
        pProducer.start()

        ### setup json writers
        lConsumerArgs = []

        for iCtr in range(0, dConfig['forks']):

            lConsumerArgs.append( (dConfig) )

        # create pool of workers 
        oConsumerPool = multiprocessing.Pool(processes=dConfig['forks'])

        ### do work -- use pool of workers to search for each search string in muse-corpus-source es index
        oConsumerPool.map(writeBuildSummaries, lConsumerArgs)

        # wait for the producer to complete
        pProducer.join()

        # wait for the consumer pool to complete
        oConsumerPool.close()
        oConsumerPool.join()
        '''

        '''
        # single process approach:
        '''
        createBuildSummaries(dConfig) 
        writeBuildSummaries(dConfig)

        if dConfig['debug']: debug('func: main()', "all processes completed") 

        iEnd = time.time()

        printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
