#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# updates any metadata archives in the corpus if something has changed 
# need to supply corpus path

count=1

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects."
    exit 4
fi

src=$1

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |
while read project
do

  if [  -f $project/index.json ]; then
#   echo "Working on $((count++)) project: $project ================="

    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    meta_tgz=$uid"_metadata.tgz"
    repo=$(jq -r .repo $project/index.json)

    # check for updated project metadata  
    found=$(redis-cli smembers "set:metadata-updated" | grep $uid)
    if [[ ! -z "$found" ]]; then
       #run it
       echo "Update found; $((count++)) project: $project ================="
       cd $project
       tar czf $meta_tgz *.txt *.json $repo doxygen/
    fi
    echo "-------------------------"
    echo ""
  fi
done

