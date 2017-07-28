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
log='addProjectNames2.txt'

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects req."
    exit 4
fi

src=$1
echo "" > $log

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |

while read project

do
    index=$project/index.json
    if [ -f $index ]; then
       repo=$(jq -r .repo $index)


       info=$project/$repo/info.json
       info_tmp=$project/$repo/info.json.tmp
       if [ -f $info ]; then

         hasName=$( jq -r 'has("name")' $info)
         hasFullName=$( jq -r 'has("full_name")' $info)
         if [ "$hasName" = true ]; then
           if [ "$hasFullName" = false ]; then
	     echo "  adding full name"
             name=$(jq -r .name $info)
             jq '. + {"full_name": "'"$name"'"}' $info > $info_tmp
             mv $info_tmp $info
             ((ucount++))
             echo $project >> $log
           fi
         fi
         if [ "$hasFullName" = true ]; then
           if [ "$hasName" = false ]; then
	     echo "  adding name"
             fname=$(jq -r .full_name $info)
	     echo "  adding name: $fname"
              jq '. + {"name": "'"$fname"'"}' $info > $info_tmp
              mv $info_tmp $info
             ((ucount++))
             echo $project >> $log
           fi
         fi
       fi
      echo "$((ucount)) of $((count++)) finished project: $project"
      echo "-----------------------------" 
    fi   
done
