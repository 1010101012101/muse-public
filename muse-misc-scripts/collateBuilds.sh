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
log="newBuilds.txt"

src="/data/builder_SAN/fedora21" 
src1="/data/builder_SAN/output" 
src2="/data/builder_SAN/output2"
xtfs="/data/corpus-xtfsvol" 
echo $src

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |
while read project
do
   path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
   uid=$(echo $project | rev | cut -d "/" -f 1 | rev)

   xtfsBuild=$xtfs/$path/buildResults/
   org=$src1/$path/
   orgBuild=$src1/$path/build.json
   org2=$src2/$path/
   orgBuild2=$src2/$path/build.json

   if [ -f $project/build.json ]; then
     result=$(jq -r .buildStatus $project/build.json)
     if [ "$result" == "success" ] || [ "$result" == "partial" ]; then
        if [ -f $orgBuild ]; then
          result2=$(jq -r .buildStatus $orgBuild)
          if [ "$result2" == "fail" ]; then
             echo "$((count++))"
             echo "$project" > $log
#             sudo cp -fr $project/build.json $org
#             sudo cp -fr $project/*.tgz $org
#             mkdir -p $xtfsBuild
#             cp -fr $project/*.tgz $xtfsBuild
          fi
          
        elif [ -f $orgBuild2 ]; then
          result2=$(jq -r .buildStatus $orgBuild2)
          if [ "$result2" == "fail" ]; then
             echo "$((count++))"
             echo "$project" > $log
#             sudo cp -fr $project/build.json $org2
#             sudo cp -fr $project/*.tgz $org2
#             mkdir -p $xtfsBuild
#             cp -fr $project/*.tgz $xtfsBuild
          fi
        fi
     fi

 
   fi


done

