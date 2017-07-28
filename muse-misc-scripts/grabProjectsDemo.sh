#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Copy projects from src path into the SAN volume
# just needt to supply src path

count=1

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to copy to the SAN is required."
    exit 4
fi

src=$1
log="500sample.txt"
dest1="/data/corpus_8tof"
dest3="/data/corpus_0to7"
xtfs="/data/corpus-xtfsvol"
dest=$dest1

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |

while read project
do

if [ -f $project/github/info.json ]; then

     lang=$(jq -r .language $project/github/info.json)

     noatm=$(jq -r .buildStatus $project/filter.json)
     echo $noatm
     if [[ "$noatm" != "no_attempt" ]]; then

     if [[ "$lang" == "C" ]] || [[ "$lang" == "C++" ]]; then
        echo "found $((count++))"
        echo $project >> $log
     fi
     fi

fi

done

