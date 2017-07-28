#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

count=1
ucount=0
log='projectIDs.txt'

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects req."
    exit 4
fi

src=$1
#echo "" > $log

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |

while read project

do
    index=$project/index.json
    if [ -f $index ]; then

       repo=$(jq -r .repo $index)
       if [[ "$repo" == "github" ]]; then
         id=$(jq -r .site_specific_id $index)
         echo $id >> $log
       fi


      echo "$((count++)) finished project: $project"
      echo "-----------------------------" 
    fi   
done
