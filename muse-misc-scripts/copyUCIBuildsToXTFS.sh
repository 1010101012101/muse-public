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
src="/data/PH2JavaBuilds/" # nfsmount on muse2
#src="/raid5/clopes/all_builds_take3/"
dest="/data/corpus-xtfsvol/"
echo $src

#Loop through all projects
find $src -mindepth 10 -maxdepth 10 -type d  |
while read project
do
   path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
   uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
   build_tgz=$uid"_UCI_build.tgz"

   destpath=$dest$path/buildResults/

   if [ -f $destpath$build_tgz ]; then
      rm -fr $destpath$build_tgz
      echo "  already exists, skipping"
#      continue
   fi

   # if destpath doesnt exist, create it
   mkdir -p $destpath

   # tar up build directory and send to XTFS 
   cd $project
   echo "$((count++))  tar czf $destpath$build_tgz *" 
   tar czf $destpath$build_tgz * 


   echo "======================"
done

