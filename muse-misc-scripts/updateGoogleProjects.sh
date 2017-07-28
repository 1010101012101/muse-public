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


if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to copy to the SAN is required."
    exit 4
fi

src=$1

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |

while read project

do
    index=$project/index.json
    if [ -f $index ]; then
       echo "$((count++)) working on project: $project"
       new=$project/index.json.tmp
       meta=$( cat $index | jq  .crawler_metadata )


       echo "  adding site google"
       jq '. + {"site": "google"}' $index > $new
       mv $new $index


       info=$project/google/info.json
       info_tmp=$project/google/info.json.tmp
       if [ -f $info ]; then
         echo "  adding info name"
         fname=$(jq -r .full_name $info)
         jq '. + {"name": "'$fname'"}' $info > $info_tmp
         mv $info_tmp $info
       fi

       #check crawler_metadata for commits json
       if [[ -n "$meta" ]]
       then
         exists=false
         case "${meta[@]}" in  *"google/commits.json"*) exists=true ;; esac

         # if path for json doesnt exist insert it into craweler metadata
         if (! $exists)
         then
           echo "  adding commits.json to crawler_metadata"
           jq '.crawler_metadata |= .+ ["./google/commits.json"]' $index > $new
           mv $new $index
         fi
       fi

      echo "-----------------------------" 
    fi   
done
