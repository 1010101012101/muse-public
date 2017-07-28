#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Iterate all corpus projects; read/parse files from each project
AVEIFS=$IFS
IFS=$(echo -en "\n\b")

count=1
fcount=0
path="/data/corpus/"

#Loop through all projects
for project in $(find $path -maxdepth 10 -mindepth 10 -type d -name java2s)
do
   echo "Working on $((count++)) project: $project"

  # Read and parse index.json for paticular values

  if [  -f $project/index.json ]; then
    version=$( cat $project/index.json | jq -r .version )
    echo "$version" 
    fcount=0
    if [[ "$version" != "none" ]]; then

       if [ -f $project/$version/source.jar ]; then
         ((fcount=fcount+1))
       else
	  echo "No source.jar found"
       fi
    else
       echo "    No version defined in index.json: $project" 
    fi # end if code exists
  fi
  echo "----$fcount-files-found-----------"
  echo ""
done
IFS=$SAVEIFS
