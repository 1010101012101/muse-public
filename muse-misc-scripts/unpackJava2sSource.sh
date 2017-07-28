#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Iterate all corpus projects; unpacks Java2s source jars 
AVEIFS=$IFS
IFS=$(echo -en "\n\b")

count=1
fcount=0
path="/data/corpus/"

#Loop through all projects
for project in $(find $path -maxdepth 10 -mindepth 10 -type d -name java2s)
do

   project=$(echo $project | rev | cut -d "/" -f 2- | rev)
   echo "Working on $((count++)) project: $project"
  # Read and parse index.json for paticular values

  if [  -f $project/index.json ]; then
    name=$( cat $project/index.json | jq -r .name )
#    numVersions=$( cat $project/index.json | jq -r '.version_history | length' )
#    latest=$( cat $project/index.json | jq -r .version_history[$((numVersions-1))])

    if [ -d $project/$name ]; then
       sources=$( ls $project/$name | grep sources)

       if [ -n "$sources" ]; then
          ((fcount=fcount+1))
          latest=$( echo $sources | rev | cut -d " " -f 1 | rev)
       	  echo "   "$sources 
          echo "   Latest: " $latest

          jq  '. + {"code": "./latest"}' $project/index.json > $project/index.json.tmp
          mv $project/index.json.tmp $project/index.json

          mkdir -p $project/latest
          cd $project/latest
          jar -xf $project/$name/$latest
       else
	  echo "   No source jars found..."
       fi
    else
       echo "    No project name defined in index.json " 
    fi # end if code exists
  fi
  echo "----$fcount-src-jars-unpacked-----------"
  echo ""
done
IFS=$SAVEIFS
