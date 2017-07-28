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
count=1

#src="/data/UCIbuilds/" # nfsmount on muse2
src="/data/PH2JavaBuilds/" # nfsmount on muse2
#src="/raid5/clopes/all_builds_take3/"
dest="/data/UCIbuilds/"
echo $src
log='phase2_java.txt'


#Loop through all projects
find $src -mindepth 10 -maxdepth 10 -type d  |
while read project
do
   path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
   uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
   build_tgz=$uid"_UCI_build.tgz"

   destpath=$dest$path/

   if [ -f $destpath ]; then
      rm -fr $destpath/*
      echo "  already exists, removing"
#      continue
   fi

   # jsut want to count overall success rate
   #if [ -f $project/build-result.json ]; then
   #   status=$(jq -r .success $project/build-result.json)
   #   echo "status: $status"
   #   if [ "$status" == "true" ]; then
   #      echo "$((counts++)) success"
   #   fi 
   #fi 

   #if destpath doesnt exist, create it
   mkdir -p $destpath

#   echo $destpath >> $log
   # tar up build directory and send to XTFS 
   echo "$((count++))  cp -fr $project/* $destpath " 
   cp -fr $project/* $destpath 


   echo "======================"
done

