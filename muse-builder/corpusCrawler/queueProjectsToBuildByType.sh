#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# with project crawling turned on
#today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --corpus-dir-path=/data/corpus_0to7 --crawl-projects --debug >/data/crawl/out/queueCrawlProjectsToBuildByType_$today.log 2>/data/crawl/err/queueCrawlProjectsToBuildByType_$today.log
#today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --corpus-dir-path=/data/corpus_8tof --crawl-projects >/data/crawl/out/queueCrawlProjectsToBuildByType_$today.log 2>/data/crawl/err/queueCrawlProjectsToBuildByType_$today.log

# with project crawling turned off and analyze on
#today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --analyze-projects --debug >/data/crawl/out/queueAnalyzeProjectsToBuildByType_$today.log 2>/data/crawl/err/queueAnalyzeProjectsToBuildByType_$today.log
#today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --analyze-projects >/data/crawl/out/queueAnalyzeProjectsToBuildByType_$today.log 2>/data/crawl/err/queueAnalyzeProjectsToBuildByType_$today.log

# queue projects for building
# today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --queue-projects="configure.ac" --debug >/data/crawl/out/queueProjectsToBuildByType_ac_$today.log 2>/data/crawl/err/queueProjectsToBuildByType_ac_$today.log

# today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --queue-projects="configure.in" --debug >/data/crawl/out/queueProjectsToBuildByType_in_$today.log 2>/data/crawl/err/queueProjectsToBuildByType_in_$today.log
# today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --queue-projects="CMakeLists.txt" --debug >/data/crawl/out/queueProjectsToBuildByType_cmake_$today.log 2>/data/crawl/err/queueProjectsToBuildByType_cmake_$today.log
# today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --queue-projects="configure" --debug >/data/crawl/out/queueProjectsToBuildByType_configure_$today.log 2>/data/crawl/err/queueProjectsToBuildByType_configure_$today.log
# today=`date "+%Y%m%d%H%M%S"`;python queueProjectsToBuildByType.py --queue-projects="Makefile" --debug >/data/crawl/out/queueProjectsToBuildByType_make_$today.log 2>/data/crawl/err/queueProjectsToBuildByType_make_$today.log

# queue projects to build into redis queues

today=`date "+%Y%m%d%H%M%S"`
outFile="/data/crawl/out/queueProjectsToBuildByType_${today}.log"
errFile="/data/crawl/err/queueProjectsToBuildByType_${today}.log"

# python queueProjectsToBuildByType.py --queue-projects --debug >$outFile 2>$errFile

#python queueProjectsToBuildByType.py --queue-projects --unbuilt-projects-only >$outFile 2>$errFile

python queueProjectsToBuildByType.py --queue-projects >$outFile 2>$errFile

# python queueProjectsToBuildByType.py --queue-projects --queue-site=fedora >$outFile 2>$errFile
