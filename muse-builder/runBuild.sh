#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

startTime=`date +%s`

touch /output/start.txt


################################################### build target: latest/datetime###
cd /source
cd latest/datetime
/scripts/make.sh > /output/stdout.log.0 2> /output/stderr.log.0
ret=$?
echo "$ret" > /output/retcode.log.0
################################################

################################################### build target: latest/utility###
cd /source
cd latest/utility
/scripts/make.sh > /output/stdout.log.1 2> /output/stderr.log.1
ret=$?
echo "$ret" > /output/retcode.log.1
################################################

################################################### build target: latest/protobuf###
cd /source
cd latest/protobuf
/scripts/make.sh > /output/stdout.log.2 2> /output/stderr.log.2
ret=$?
echo "$ret" > /output/retcode.log.2
################################################

################################################### build target: latest/topk###
cd /source
cd latest/topk
/scripts/make.sh > /output/stdout.log.3 2> /output/stderr.log.3
ret=$?
echo "$ret" > /output/retcode.log.3
################################################

################################################### build target: latest/faketcp###
cd /source
cd latest/faketcp
/scripts/make.sh > /output/stdout.log.4 2> /output/stderr.log.4
ret=$?
echo "$ret" > /output/retcode.log.4
################################################

################################################### build target: latest/reactor###
cd /source
cd latest/reactor
/scripts/make.sh > /output/stdout.log.5 2> /output/stderr.log.5
ret=$?
echo "$ret" > /output/retcode.log.5
################################################

################################################### build target: latest/sudoku###
cd /source
cd latest/sudoku
/scripts/make.sh > /output/stdout.log.6 2> /output/stderr.log.6
ret=$?
echo "$ret" > /output/retcode.log.6
################################################

################################################### build target: latest/thread###
cd /source
cd latest/thread
/scripts/make.sh > /output/stdout.log.7 2> /output/stderr.log.7
ret=$?
echo "$ret" > /output/retcode.log.7
################################################

################################################### build target: latest/datetime###
cd /source
cd latest/datetime
/scripts/make.sh > /output/stdout.log.0 2> /output/stderr.log.0
ret=$?
echo "$ret" > /output/retcode.log.0
################################################

################################################### build target: latest/utility###
cd /source
cd latest/utility
/scripts/make.sh > /output/stdout.log.1 2> /output/stderr.log.1
ret=$?
echo "$ret" > /output/retcode.log.1
################################################

################################################### build target: latest/protobuf###
cd /source
cd latest/protobuf
/scripts/make.sh > /output/stdout.log.2 2> /output/stderr.log.2
ret=$?
echo "$ret" > /output/retcode.log.2
################################################

################################################### build target: latest/topk###
cd /source
cd latest/topk
/scripts/make.sh > /output/stdout.log.3 2> /output/stderr.log.3
ret=$?
echo "$ret" > /output/retcode.log.3
################################################

################################################### build target: latest/faketcp###
cd /source
cd latest/faketcp
/scripts/make.sh > /output/stdout.log.4 2> /output/stderr.log.4
ret=$?
echo "$ret" > /output/retcode.log.4
################################################

################################################### build target: latest/reactor###
cd /source
cd latest/reactor
/scripts/make.sh > /output/stdout.log.5 2> /output/stderr.log.5
ret=$?
echo "$ret" > /output/retcode.log.5
################################################

################################################### build target: latest/sudoku###
cd /source
cd latest/sudoku
/scripts/make.sh > /output/stdout.log.6 2> /output/stderr.log.6
ret=$?
echo "$ret" > /output/retcode.log.6
################################################

################################################### build target: latest/thread###
cd /source
cd latest/thread
/scripts/make.sh > /output/stdout.log.7 2> /output/stderr.log.7
ret=$?
echo "$ret" > /output/retcode.log.7
################################################


endTime=`date +%s`
runTime=$(( endTime - startTime ))

for foundFile in `find / -type f -newer /output/start.txt -print -o -path '/dev' -prune -o -path '/etc' -prune -o -path '/proc' -prune -o -path '/sys' -prune -o -path '/tmp' -prune -o -path '/usr' -prune -o -path '/var' -prune`; do rsync -aR $foundFile /buildArtifacts/; done

echo $runTime > /output/runtime.log

find /buildArtifacts/ -type f -name "*.o" >> /output/objects.log

wc -l < /output/objects.log > /output/numObjects.log

find /source/ -type f -name "*.c" >> /output/sources.log

find /source/ -type f -name "*.cxx" >> /output/sources.log

find /source/ -type f -name "*.cpp" >> /output/sources.log

find /source/ -type f -name ".c++" >> /output/sources.log

find /source/ -type f -name ".cc" >> /output/sources.log

wc -l < /output/sources.log > /output/numSources.log

dmesg > /output/dmesg.log

touch /output/done.txt

