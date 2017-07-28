muse-builder
============

1: Overview
------------------------------------------------
This directory contains the code for running the builder code. First the corpus needs to be crawled and indexed so that a build queue can be created. Once the queue is made, the builder can be run over it. buildProjectsByType.sh can be edited to chose which operating systems to run on (Ubuntu 12, Ubuntu 14, Fedora 20, Fedora 21). The process can be run by calling the 3 scripts below or by following the later instructions in this README.

    corpusInspector.sh
    queueProjectsToBuildByType.sh
    buildProjectsByType.sh

2:  Crawl corpus for src files to be indexed into ES
------------------------------------------------
Index into ES all files contained in the <uuid>_code.tgz archive file of each project contained in corpusPath argument).  Uses redis to queue project paths to crawl (queue:muse-project-paths). Uses ES to store project files (muse-corpus-source-new).
By default it will flush both ES index and Redis queue and start from scratch. ( ~40 hrs / half corpus)

file crawler is usually run from muse1 where the file crawls will be faster but can be easily pointed at a NFS share instead (assuming the same uuid directory structure under the corpus root)

sample call to crawler:

    today=`date "+%Y%m%d%H%M%S"`;python corpusInspector.py --corpus-dir-path=/data/corpus_0to7 --forks=10 --redis >/data/crawl/out/corpusInspector_${today}.redis.log 2>/data/crawl/err/corpusInspector_${today}.redis.log

there are a series of knobs for this file crawling script that have not been parametrized as flags to the script (found at the top of the main function in the corpusInspector.py script) because they aren't likely to change much if at all, including:

    dConfig['es-bulk-chunk-size'] = 500
    dConfig['es-instance-locs'] = ['muse1-int','muse2-int','muse3-int']
    dConfig['es-index-name'] = 'muse-corpus-source-new'  ## ES index where all source files are placed
    dConfig['es-index-type'] = 'files'  ## ES index type
    dConfig['redis-queue-name'] = 'muse-project-paths'  ##(simply used to queue project paths to then index files into ES;  pops off queue as it goes)
    dConfig['redis-loc'] = 'muse2-int'
    dConfig['redis-port'] = '12345'
    note the redis port here. A separate redis container has been spawned on a different/non-standard port to segregate builds from the other crawling infrastructure.

Check if working:  

    ES:  curl localhost:9200/muse-corpus-source-new/files/_count?pretty (counter for files being indexed)
    Redis:  redis-cli -h muse2-int -p 12345;  llen "queue:muse-project-paths" (counter for project paths left to crawl)

3:  Crawl projects for project meta-data
----------------------------------------
(meta-data includes project languages, source site, etc...)
(resets and fills "projects" table in MySql) ( ~10 mins / half corpus)

    today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --corpus-dir-path=/data/corpus_0to7 --crawl-projects >/data/crawl/out/queueProjectsToBuildByType_$today.log 2>/data/crawl/err/queueProjectsToBuildByType_$today.log

Check is working:   

    mysql -u muse -h muse2-int -p 54321 -p ;  use muse;  select count(*) from projects;

4:  Analyze files in elasticsearch index for build targets
---------------------------------------------------------
we're looking for build scripts (fMakefile, configure, configure.ac, configure.in, CMakeLists.txt) and
fills buildTargets and unBuiltTargets tables in Mysql.

Also looks for sourceTargets (.c, cpp, etc) and fills sourceTargets table in Mysql) ( ~50 hrs / half corpus)

    today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --analyze-projects >/data/crawl/out/queueProjectsToBuildByType_$today.log 2>/data/crawl/err/queueProjectsToBuildByType_$today.log

Check is working:   

    mysql -u muse -h muse2-int -p 54321 -p;  use muse;  select count(*) from buildTargets;  select count(*) from sourceTargets;   (should have counts for both targets tables)

5: Queue projects for building  
------------------------------
uses MySQL to look at projects to build or rebuild
based on build/sourceTargets and queues them up into redis queue :  queue:project-to-build)

    today=`date "+%Y%m%d%H%M%S"`
    outFile="/data/crawl/out/queueProjectsToBuildByType_${today}.log"
    errFile="/data/crawl/err/queueProjectsToBuildByType_${today}.log"
    python queueProjectsToBuildByType.py --queue-projects >$outFile 2>$errFile

    //queued projects can be tuned as well to target unbuilt projects or projects from a specific site (or both), i.e.
    python queueProjectsToBuildByType.py --queue-projects --unbuilt-projects-only >$outFile 2>$errFile
    python queueProjectsToBuildByType.py --queue-projects --queue-site=fedora >$outFile 2>$errFile

Check is working:  

    redis-cli -h muse2-int -p 12345;  llen(queue:projects-to-build);

6:  Build projects (on muse1):  (buildProjectsByType.py )
-----------------------------
Set the output folder in this python script to where you want the output artifacts to be placed:

    sBuildPath = os.path.join('/data/builder_SAN/output', sProjectPath)

the call to the clean up script, though not explicitly required, removed existing build containers and directories and prepares a fresh environment for projects to be built as scheduled in the redis queue from Step 5.

    ./cleanUpBuildProjectsByType.sh && ./buildProjectsByType.sh

the buildProjectsByType.py shell script wraps a python process that spawns the docker containers and per-container build managers. It can be tuned by passing in different os containers for building.

code snippet from the shell script:

    for buildOS in 'ubuntu14' 'ubuntu12' 'fedora20' 'fedora21'
    do
        today=`date "+%Y%m%d%H%M%S"`
        outFile="/data/crawl/out/buildProjectsByType_${buildOS}_${today}.log"
        errFile="/data/crawl/err/buildProjectsByType_${buildOS}_${today}.log"
        ###############################################################################################################
        echo "using buildOS ${buildOS}"
        python buildProjectsByType.py --forks=10 --os="${buildOS}" >>$outFile 2>>$errFile
        ###############################################################################################################
    done

the shell script is not required however and the python script can be called directly with the os container and the number of build managers/containers to spawn.

7:  Monitor build indexes
-------------------------
While crawls are being performed and indexes added to elasticsearch, I usually monitor the build indexes with the following watch in a screen session on muse2:

    watch -n 60 "curl 'localhost:9200/_cat/indices?v'"

8:  Monitor build status in mysql and redis
------------------------------------------
While builds are being performed, I usually monitor build status in mysql and redis (note the non-standard ports on both, both containers are on muse2) (mysql password is 'muse'):

    mysql -h muse2-int -u muse --port 54321 -p

    Enter password:
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 135080
    Server version: 5.5.43-0ubuntu0.14.04.1-log (Ubuntu)


    mysql> use muse;
    Reading table information for completion of table and column names
    You can turn off this feature to get a quicker startup with -A

    Database changed


mysql> SELECT * FROM buildSummaryByOS ORDER BY os,builds;


    +--------------+----------+-----------+
    | projectCount | os       | builds    |
    +--------------+----------+-----------+
    |         1345 | fedora20 | fails     |
    |          312 | fedora20 | partials  |
    |          210 | fedora20 | successes |
    |         2109 | fedora20 | totals    |
    |         1793 | fedora21 | fails     |
    |          392 | fedora21 | partials  |
    |          953 | fedora21 | successes |
    |         3780 | fedora21 | totals    |
    |        14139 | ubuntu12 | fails     |
    |         4137 | ubuntu12 | partials  |
    |         1308 | ubuntu12 | successes |
    |        20187 | ubuntu12 | totals    |
    |        28243 | ubuntu14 | fails     |
    |         5025 | ubuntu14 | partials  |
    |        12465 | ubuntu14 | successes |
    |        48742 | ubuntu14 | totals    |
    +--------------+----------+-----------+
    16 rows in set (2 min 3.53 sec)

mysql> SELECT * FROM buildSummary; SELECT * FROM buildSummaryBySite ORDER BY site,builds;

    +--------------+-----------+
    | projectCount | builds    |
    +--------------+-----------+
    |        14939 | successes |
    |         5562 | partials  |
    |        28241 | fails     |
    |        48742 | totals    |
    +--------------+-----------+
    4 rows in set (1 min 33.92 sec)

    +--------------+-------------+-----------+
    | projectCount | site        | builds    |
    +--------------+-------------+-----------+
    |         1551 | fedora      | fails     |
    |          447 | fedora      | partials  |
    |         3535 | fedora      | successes |
    |         5533 | fedora      | totals    |
    |        25383 | github      | fails     |
    |         4978 | github      | partials  |
    |        11052 | github      | successes |
    |        41413 | github      | totals    |
    |         1296 | google      | fails     |
    |          136 | google      | partials  |
    |          347 | google      | successes |
    |         1779 | google      | totals    |
    |            2 | SourceForge | fails     |
    |            2 | SourceForge | totals    |
    |            9 | uciMaven    | fails     |
    |            1 | uciMaven    | partials  |
    |            5 | uciMaven    | successes |
    |           15 | uciMaven    | totals    |
    +--------------+-------------+-----------+
    18 rows in set (1 min 37.94 sec)

redis-cli -h 127.0.0.1 -p 12345
127.0.0.1:12345> keys *

    1) "set:muse-already-built-ubuntu14"
    2) "set:muse-already-built-ubuntu12"
    3) "queue:muse-to-build"
    4) "set:muse-projects-partial"
    5) "queue:muse-building"
    6) "set:muse-projects-fail"
    7) "set:muse-projects-success"
    127.0.0.1:12345> llen queue:muse-to-build
    (integer) 13596


If there's interest in augmenting build targets or source targets, the following needs to be modified (assuming no special handling is required):

For traditional build targets (Makefile, configure script, etc...), the findBuildTargets() method in queueProjectsToBuildByType.py needs to be updated with the appropriate elasticsearch DSL:

    dQuery = {
        "query": {
            "bool": {
                "must": [
                    { "bool": {
                        "should": [
                            { "term": { "file.raw": "configure.ac" } },
                            { "term": { "file.raw": "configure.in" } },
                            { "term": { "file.raw": "configure" } },
                            { "term": { "file.raw": "CMakeLists.txt" } },
                            { "term": { "file.raw": "Makefile" } }
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
                    }
                ]
            }
        }
    }

For source targets (.cpp, .c, etc... files), the findSourceTargets() method in queueProjectsToBuildByType.py needs to be updated with the appropriate elasticsearch DSL. The current DSL looks like this (sProjectName is resolved in the function):
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

The following dictionaries have to be updated in queueProjectsToBuildByType.py as well:
The build targets dictionary provides build type rankings so builds will prioritize the lowest ranking to the highest for build order (i.e. starting from 1, then 2, etc...)

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

If additional types are required, tables in mysql will need to be updated to reflect schema changes (primarily buildTargets, buildStatus and buildStatusTargets as needed and the mysql helper libraries in projectDB.py should be updated to reflect table/view changes).
In the buildProjectsByType.py script, changes to traditional build targets will require new shell scripts to wrap the build process for those targets. The new shell scripts usually created in the builder.scripts salt state (found under /srv/salt/builder/scripts.sls and the build scripts are under /srv/salt/builder/files on muse2). Once the shell scripts are in place the following dictionaries (found in the main() method) should be updated reflecting the names/locations of the shell scripts (though the expectation is the shell scripts will all appear under /managed/scripts if the salt state pre-existing examples were followed):

host directory structure

    dArgs['buildScripts'] = {}
    dArgs['buildScripts']['root'] = '/managed/scripts'
    dArgs['buildScripts']['loader'] = os.path.join( dArgs['buildScripts']['root'], 'runBuild.sh' )
    dArgs['buildScripts']['cmakeBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'cmake.sh' )
    dArgs['buildScripts']['configureBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configure.sh' )
    dArgs['buildScripts']['configureacBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configureac.sh' )
    dArgs['buildScripts']['configureinBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'configurein.sh' )
    dArgs['buildScripts']['makefileBuildType'] = os.path.join( dArgs['buildScripts']['root'], 'make.sh' )

container directory structure

    dArgs['containerScripts'] = {}
    dArgs['containerScripts']['root'] = '/scripts'
    dArgs['containerScripts']['cmakeBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'cmake.sh' )
    dArgs['containerScripts']['configureBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'configure.sh' )
    dArgs['containerScripts']['configureacBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'configureac.sh' )
    dArgs['containerScripts']['configureinBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'configurein.sh' )
    dArgs['containerScripts']['makefileBuildType'] = os.path.join( dArgs['containerScripts']['root'], 'make.sh' )

If source targets are modified, the source-compiler dictionary needs to be updated (found in main() method of buildProjectsByType.py):

    dArgs['source-compilers'] = {
        'cBuildType' : 'gcc',
        'cppBuildType' : 'g++'
    }

If additional flags/handling are required for the new source type (gcc/g++ handling assumes the standard gcc source-file -o object-file notation), the following conditional in createBuildPlanScript() in buildProjectsByType.py needs to be modified:

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
