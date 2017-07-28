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
find $src -mindepth 9 -maxdepth 9 -type d  |
while read project
do
   path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
   uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
   build_tgz=$uid"_buildbot.tgz"

   destpath=$dest$path/buildResults/

   if [ -f $destpath$build_tgz ]; then
      echo "  already exists, skipping"
      continue
   fi

   # if destpath doesnt exist, create it
   mkdir -p $destpath

   # tar up build directory and send to XTFS 
   if [ -f $project/build.json ]; then
     status=$(jq -r .buildStatus $project/build.json)
     if [ "$status" != "failur" ]; then
       cd $project
       echo "$((count++))  tar czf $destpath$build_tgz *" 
       tar czf $destpath$build_tgz * 
     fi
   fi

   echo "======================"
done

