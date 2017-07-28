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
path=/data/corpus/

for project in $(find $path -maxdepth 9 -mindepth 9 -type d)
do
    index=$project/index.json
    if [ -f $index ]; then
       echo "$((count++)) working on project: $project"
       new=$project/index.json.tmp

        var=$(jq . $index)
        if [ "$var" ]
        then
            echo "adding corpus release"
            jq '. + {"corpus_release": "1.0"}' $index > $new
            mv $new $index
        fi
      echo "-----------------------------" 
    fi   
done
