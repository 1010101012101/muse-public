#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Remove empty projects from XTFS or projects that no longer exist in SAN 

count=0
countr=0
countb=0
countbb=0


#if [[ $# != 1 ]]; then
#    echo "$0: A path to the projects is required."
#    exit 4
#fi

#src=$1

dest1="/data/corpus_8tof"
dest3="/data/corpus_0to7"
xtfs="/data/corpus-xtfsvol"
found=false
#Loop through all projects in XTFS
find $xtfs -mindepth 9 -maxdepth 9 -type d  |

while read project
do

   ((count++))
   found=false
   path=$(echo $project | cut -d "/" -f 4-12 )
   uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
#   echo "loooking for: $dest$path"
   
   if [ -d $dest1/$path ]; then
      found=true
      if [ ! -f $dest1/$path/$uid.tgz ]; then
         echo "no archives in projects"
      fi 
   fi 
   if [ -d $dest3/$path ]; then
      found=true
      if [ ! -f $dest3/$path/$uid.tgz ]; then
         echo "no archives in projects"
      fi 
   fi

   if [ "$found" = false ]; then
      echo "$count Project not found in SAN $((++countr)): $project"
      #echo "rm -fr $project/"
      rm -fr $project/
   fi
   old_build=$uid"_build.tgz"
   if [ -f $project/$old_build ]; then
      echo  "$count found old build tgz $((++countb)): $project"
      rm -fr $project/$old_build
   fi
   if [ -f $project/buildResults/$old_build ]; then
      echo  "$count found old buildResults tgz $((++countbb)): $project/buildResults"
      rm -fr $project/buildResults/$old_build
   fi
done


