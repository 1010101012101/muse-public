#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

#  Extract all files from a project along with their associated size in bytes 
#  writing to "file_sizes.txt"

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to use."
    exit 4
fi

src=$1

count=1
tmp="/home/muse/extractors/file_sizes/tmpab"
tmpList=$tmp"/tarlist.txt"
mkdir -p $tmp

#Loop through all projects
#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |

while read project
do

 #for project in $(find $src -maxdepth 9 -mindepth 9 -type d)
 #do
  echo "Working on $((count++)) project: $project ================="

  if [  -f $project/index.json ]; then

    uid=$( cat $project/index.json | jq -r .uuid )
    archive=$uid"_code.tgz"
    output=$project/file_sizes.txt
    if [ -f $output ]; then
       continue
    fi

    if [[ ${uid:0:1} == a || ${uid:0:1} == b ]]; then
    
      # check to ensure src code location was specified in index.json
      if [ -f $project/$archive ]; then
         echo "" > $output

         echo "tar tzvf $project/$archive > $tmpList"
         tar tzvf $project/$archive | grep -v '/$' > $tmpList

         while read file; do
           size=$(echo $file| cut -d " " -f 3)
           path=$(echo $file | cut -d " " -f 6)
           #echo "   $size,$path"
           echo "$size,$path" >> $output
         done < $tmpList
      fi
      rm -fr $tmp/*
    fi
  fi
  echo ""
done






