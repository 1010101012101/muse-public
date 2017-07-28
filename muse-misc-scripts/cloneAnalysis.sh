#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Copy build archives to xtreemfs volume

count=1

#src="/data/UCIbuilds/" # nfsmount on muse2
src="/data/buildbot/" # nfsmount on muse2
#src="/raid5/clopes/all_builds_take3/"
dest="/data/corpus-xtfsvol/"
echo $src

#Loop through all projects
#find $src -mindepth 9 -maxdepth 9 -type d  |
while read line 
do

   echo $line
   project=$(echo $line | rev | cut -d "," -f 1 | rev)
   echo $project

#   path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    echo $uid


done < cloneDumpCpp2.csv
