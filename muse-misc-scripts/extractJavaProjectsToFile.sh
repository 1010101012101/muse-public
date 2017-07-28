#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Extract all java project paths to a text file 
# 


if [[ $# != 1 ]]; then
    echo "$0: A path to the corpus you wish to run extractor on is required."
    exit 4
fi

path=$1

echo "Running extractor over: $path"

count=1
output='java_projects_04_01_16.txt'
#echo "" > $output

#Loop through all projects
find $path -mindepth 9 -maxdepth 9 -type d  |

while read project
do
   echo "Working on $((count++)) project: $project"
   
   uuid_path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)

   if [ -f $project/index.json ]
   then
     repo=$( cat $project/index.json | jq -r .repo )
     uid=$( cat $project/index.json | jq -r .uuid )

     
     # check to ensure repo was specified in index.json
     brepo=$( jq -r 'has("repo")' $project/index.json)
     if [ "$brepo" = true ]; then

       lang=$project/$repo/languages.json

       if [ -f $lang ]
       then
          bJava=$( jq -r 'has("Java")' $lang)
          if [ "$bJava" = true ]; then
             echo "  found JAva" 
             echo "$project" >> $output
	  fi
       fi
    fi
  fi
  echo ""
done
