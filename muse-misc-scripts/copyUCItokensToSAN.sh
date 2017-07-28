#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Copy tokens.txt from src path into the SAN volume 
# just needt to supply src path

count=1

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to copy to the SAN is required."
    exit 4
fi

src=$1

dest1="/data/corpus_8tof"
dest3="/data/corpus_0to7"
xtfs="/data/corpus-xtfsvol"
dest=$dest1

#Loop through all projects
for project in $(find $src -maxdepth 9 -mindepth 9 -type d)
do
   echo "Working on $((count++)) project: $project ================="

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)

    if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
       dest=$dest3
    else
       dest=$dest1
    fi

    # skip any projects that already exist; check for empty code archives and remove
    if [ -f $dest/$path/tokens.txt ]; then
       echo "  alreaaday exists; skipping project..."
       continue
    fi 

    if [ -f $project/tokens.txt ]; then
      echo "  cp -fr $project/tokens.txt  $dest/$path/"
      cp -fr $project/tokens.txt  $dest/$path/
    else
      echo "  no token.txt"
    fi
    echo ""
done

