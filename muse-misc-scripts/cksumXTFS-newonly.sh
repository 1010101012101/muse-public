#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# find and create cksums for all tgz files given a non XTFS path.
# ideally used to create cksums from a new set of projects without
# having to recreate all chksums again. you would cat this log output
# with orginial


src=/data/arduino
dest=/data/corpus-xtfsvol
version=4_3_1  # version of xtfs corpus
log="MUSE-corpus-updateV"$version".txt"
echo $log
count=1
countp=1

find $src -mindepth 9 -maxdepth 9 -type d | 

while read project
do
   
   path=$(echo $project | rev | cut -d "/" -f -9 | rev)
   newpath=$dest/$path
   echo "$((countp++))  looking for files in: $newpath"
   find $newpath -mindepth 1 -type f |
   while read file
   do
     echo "XTFS File Count: $((count++)) $file"
     cksum $file >> $log
     echo ""
   done
done

