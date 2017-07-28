#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# remove project archive files from xtfs 1 by 1
# rsync projects from san back to xtfs so it can redistribute between 3 osd nodes

count=1


dest1="/data/corpus_8tof"
dest3="/data/corpus_0to7"
xtfs="/data/corpus-xtfsvol"
dest=$dest1

#Loop through all projects
find $xtfs -mindepth 9 -maxdepth 9 -type d  |

while read project
do

   echo "Working on $((count++)) project: $project ================="

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)

    if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
       dest=$dest3
    else
       dest=$dest1
    fi

#    if [ -f $dest/$path/index.json ]; then
#       echo "skipping project..."
#       continue
#    fi 

    # Remove XTFS archive files
#    echo "  rm -f $project/*"
#    rm -f $project/*

    # Rsync new archive files to XTFS
    # Copy doxygen json if exists
    
#    echo "  rsync -avz --progress --include '*.tgz' --exclude-from 'excludeFromRsync.txt' $dest/$path/ $project/"
#    rsync -avz --progress --include '*.tgz' --exclude-from 'excludeFromRsync.txt' $dest/$path/ $project/
    echo"  cp -fr $dest/$path/*.tgz $project/"
    cp -fr $dest/$path/*.tgz $project/
    echo ""
done
#done < ~/Nathan/newSFs.log

