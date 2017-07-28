#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

today=`date "+%Y%m%d%H%M%S"`
logPath="/home/sbhattacharyya/corpusCrawler/logs"

# with project crawling turned off and analyze on
#python queueProjects_cyber.py --analyze-projects --cyber-projects-file=cyberPhysicalBuiltTest.txt --debug >$logPath/queueAnalyzeProjectsToBuildByType_$today.out 2>$logPath/queueAnalyzeProjectsToBuildByType_$today.err

#python queueProjects_cyber.py --analyze-projects --cyber-projects-file=cyberPhysicalBuiltTest.txt >$logPath/queueAnalyzeProjectsToBuildByType_$today.out 2>$logPath/queueAnalyzeProjectsToBuildByType_$today.err

# queue projects for building
#python queueProjects_cyber.py --queue-projects="configure.ac" --debug >$logPath/queueProjectsToBuildByType_ac_$today.out 2>$logPath/queueProjectsToBuildByType_ac_$today.err

#python queueProjects_cyber.py --queue-projects="configure.in" --debug >$logPath/queueProjectsToBuildByType_in_$today.out 2>$logPath/queueProjectsToBuildByType_in_$today.err
#python queueProjects_cyber.py --queue-projects="CMakeLists.txt" --debug >$logPath/queueProjectsToBuildByType_cmake_$today.out 2>$logPath/queueProjectsToBuildByType_cmake_$today.err
#python queueProjects_cyber.py --queue-projects="configure" --debug >$logPath/queueProjectsToBuildByType_configure_$today.out 2>$logPath/queueProjectsToBuildByType_configure_$today.err
#python queueProjects_cyber.py --queue-projects="Makefile" --debug >$logPath/queueProjectsToBuildByType_make_$today.out 2>$logPath/queueProjectsToBuildByType_make_$today.err

# queue projects to build into redis queues

# python queueProjects_cyber.py --queue-projects --debug >$logPath/queueProjectsToBuildByType_$today.out 2>$logPath/queueProjectsToBuildByType_$today.err

#python queueProjects_cyber.py --queue-projects --unbuilt-projects-only >$logPath/queueProjectsToBuildByType_$today.out 2>$logPath/queueProjectsToBuildByType_$today.err

python queueProjects_cyber.py --queue-projects --debug >$logPath/queueProjectsToBuildByType_$today.out 2>$logPath/queueProjectsToBuildByType_$today.err

# python queueProjects_cyber.py --queue-projects --queue-site=fedora >$logPath/queueProjectsToBuildByType_$today.out 2>$logPath/queueProjectsToBuildByType_$today.err
