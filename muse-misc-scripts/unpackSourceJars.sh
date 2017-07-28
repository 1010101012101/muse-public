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
for project in $(find $path -maxdepth 10 -mindepth 10 -type d -name uciMaven)
do

   project=$(echo $project | rev | cut -d "/" -f 2- | rev)
   echo "Working on $((count++)) project: $project"
   numVersions=0
  # Read and parse index.json for paticular values

  if [  -f $project/index.json ]; then
    version=$( cat $project/index.json | jq -r .version )
    numVersions=$( cat $project/index.json | jq -r '.version_history | length' )
    
    latest=$( cat $project/index.json | jq -r .version_history[$((numVersions-1))])

    echo $numVersions
    echo $latest 


    if [[ "$latest" != "null" ]]; then

       if [ -f $project/$latest/source.jar ]; then
         ((fcount=fcount+1))
         mkdir -p $project/latest/
         cd $project/latest/
         jar -xf $project/$latest/source.jar

       else
	  echo "No source.jar found for version: $latest"
       fi
    else
       echo "    No version defined in index.json " 
    fi # end if code exists
  fi
  echo "----$fcount-files-found-----------"
  echo ""
done
IFS=$SAVEIFS
