#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

src="/data/corpus_0to7/"
count=1
countp=1
log='buildFails2.txt'
echo "" > $log
find $src -maxdepth 9 -mindepth 9 -type d | 

while read project  
do
   echo "Working on: $((count++)) $project"
   path=$(echo $project | rev | cut -d "/" -f -9 | rev) 

   if [ -f $project/filter.json ]; then
     result=$(jq -r .buildStatus $project/filter.json)
     if [ "$result" == "failure" ]; then
        echo "$((countp++)) $result"
        echo $project >> $log
     fi
   fi

done

