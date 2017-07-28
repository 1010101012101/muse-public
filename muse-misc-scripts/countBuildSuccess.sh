#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# used to count the build success of our Leidos Build process
src="/data/build/"
count=1
counts=1
countp=1

find $src -maxdepth 9 -mindepth 9 -type d | 

while read project  
do

   echo "Count: $((count++)) $project"
   path=$(echo $project | rev | cut -d "/" -f -9 | rev) 

   if [ -f $project/build.json ]; then
     result=$(jq -r .buildStatus $project/build.json)
     if [ "$result" == "partial" ]; then
        echo "$((countp++)) $result"
     fi
     if [ "$result" == "success" ]; then
        echo "$((counts++)) $result"
     fi
#   echo "Count: $((count++))"
   fi

done

