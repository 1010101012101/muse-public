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
ccount=1

dest="/data/UCIbuilds/" 
#src="/raid5/clopes/all_builds_take3/"
src="/data/corpus-xtfsvol/"
echo $src

#Loop through all projects
find $src -mindepth 11 -maxdepth 11 -type f -name '*UCI_build.tgz' |
while read project
do
   path=$(echo $project | rev | cut -d "/" -f 3-9 | rev)
   uid=$(echo $project | rev | cut -d "/" -f 3 | rev)

   destpath=$dest$path

   if [ -f $destpath ]; then
      echo "  already exists, skipping"
      continue
   fi

   # if destpath doesnt exist, create it
   mkdir -p $destpath

   # tar up build directory and send to XTFS 
   cd $destpath
   echo "$((ccount++))  tar xzf $project" 
   tar xzf $project  


   echo "======================"
done

