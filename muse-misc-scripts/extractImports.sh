#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Archive all projects in a given path and 
# Copy arhives into the XTFS volume 
# src - supply src path of projects to copy

count=1
if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to work is required."
    exit 4
fi

src=$1

#Loop through all projects
for project in $(find $src -maxdepth 10 -mindepth 10 -type f -name index.json)
do
 
  project=$(echo $project | rev | cut -d "/" -f 2- | rev)
  echo "Working on $((count++)) project: $project ================="
#  path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
#  uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
  if [ ! -f $project/imports.txt ]; then
   if [ $project/index.json ]; then
    uid=$(jq -r .uuid $project/index.json)
    tar=$uid".tgz"
    cd $project    
    if [ -f $tar ]; then
      echo "tar --extract --file=$tar imports.txt"
      tar --extract --file=$tar imports.txt
      echo "tar --extract --file=$tar ./imports.txt"
      tar --extract --file=$tar ./imports.txt
    fi
   fi
  else
    echo "  already have imports.txt....skipping"
  fi
  echo ""
done

