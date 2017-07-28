#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Update corpus_release tag for projects 
# just needt to supply log of project paths

count=1
dest=$dest1


#Loop through all projects

while read project
do

    index=$project/index.json
    if [ -f $index ]; then
       echo "$((count++)) working on project: $project"
       new=$project/index.json.tmp

        var=$(jq . $index)
        if [ "$var" ]
        then
            jq '. + {"corpus_release": "phase2"}' $index > $new
            mv $new $index
        fi
    fi


done < /data/buildbot/directedPH2_2.txt 

