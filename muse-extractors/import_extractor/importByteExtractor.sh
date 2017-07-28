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
for project in $(find $path -maxdepth 9 -mindepth 9 -type d)
do
   echo "Working on $((count++)) project: $project"

  # Read and parse index.json for paticular values

  if [  -f $project/filter.json ]; then
    bcode=$( cat $project/filter.json | jq -r .hasBytecode )
    scode=$( cat $project/filter.json | jq -r .hasSource )
    output=$project/importsBC.txt
    output2=$project/importsBC_Classes.txt
    echo "" > $output
    echo "" > $output2
    fcount=0
    if [[ "$bcode" != "none" ]]; then
       if [[ "$scode" == "none" ]]; then

        for file in $(find $project -type f -name '*.class')
        do
         ((fcount=fcount+1))
	 javap $file | grep -o '[[:alnum:]]*\.[[:alnum:]]*\.[[:alnum:]\.]*' | grep -oE '[^. ]+$'  >> $output2
#         grep -oE '[^. ]+$' $output > $output2
	 javap $file | grep -o '[[:alnum:]]*\.[[:alnum:]]*\.[[:alnum:]\.]*' |  sed s/'.\w*$'// >> $output
#	 sed -i s/'.\w*$'// $output 
        done
       fi
    else
       echo "    No bytecode defined in filter.json: $project" 
    fi # end if code exists
  fi
  echo "----$fcount-files-found-----------"
  echo ""
done
IFS=$SAVEIFS
