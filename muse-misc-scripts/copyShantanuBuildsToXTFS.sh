#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Copy Shantanu build archives from /nfsbuild/ to xtreemfs volume

count=1

#src="/nfsbuild/"
src="/data/nfsbuild07/"
dest="/data/corpus-xtfsvol/"
echo $src

#Loop through all projects
find $src -maxdepth 10 -mindepth 10 -type f -name '*.tgz' | 
while read archive 

do
   echo $((count++))

   path=$(echo $archive | cut -d "/" -f 4-12 )
   tgz=$(echo $archive | rev | cut -d "/" -f 1 | rev)
   destpath=$dest$path/buildResults/
   project=$(echo $archive | rev | cut -d "/" -f 2- | rev)

   if [ -f $project/build.json ]; then
    result=$(jq -r .buildStatus $project/build.json)
    echo $result
    if [ "$result" == "partial" ] || [ "$result" == "success" ]; then
     # if tgz doesnt already exist, copy it
     if [ ! -f $destpath/$tgz ]; then
       echo "mkdir -p $destpath"
       mkdir -p $destpath
       echo "Copy from: $archive"
       echo "Copy to: $destpath" 
       cp -f $archive $destpath
     else
       echo "Already exists, skipping: $destpath/$tgz" 
     fi
    fi
   fi
   echo "======================"
done

