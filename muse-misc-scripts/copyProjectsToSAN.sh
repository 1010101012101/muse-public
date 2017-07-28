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

dest1="/data/corpus_8tof"
dest3="/data/corpus_0to7"
dest=$dest1

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |

while read project
do

  if [  -f $project/index.json ]; then
   echo "Working on $((count++)) project: $project ================="

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    code_tgz=$uid"_code.tgz"
    meta_tgz=$uid"_metadata.tgz"
    other_tgz=$uid".tgz"
    repo=$(jq -r .repo $project/index.json)
    code=$(jq -r .code $project/index.json)

    if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
       dest=$dest3
    else
       dest=$dest1
    fi

    if [ -d $dest/$path ]; then
       continue
    fi

    mkdir -p $dest/$path

    # Copy over metadata folder
    if [ -d $project/$repo ]; then
      echo "  cp -fr $project/$repo/  $dest/$path/"
      cp -fr $project/$repo/  $dest/$path/
      cd $project
      echo "  tar czf $dest/$path/$meta_tgz $repo/"
      tar czf $dest/$path/$meta_tgz $repo/
    fi  

    if [ -d $project/doxygen ]; then
       echo "  cp -fr $project/doxygen/ $dest/$path"
       cp -fr $project/doxygen/ $dest/$path
    fi

    # Copy over json, text files
    echo "  cp -fr $project/*.txt $project/*.json $dest/$path/"
    cp -fr $project/*.txt $project/*.json $dest/$path/

    code=$(echo $code | cut -d "/" -f 2)
    # Archive the latest src of each project, if exists
    if [ -d $project/$code ]; then
       cd $project
       echo "  tar czf $dest/$path/$code_tgz $code/"
       tar czf $dest/$path/$code_tgz $code/
    fi  

    # tar up any remaining files
    cd $project
    echo "  tar czf $dest/$path/$other_tgz * --exclude=$repo --exclude=$code"  
    tar czf $dest/$path/$other_tgz * --exclude=$repo --exclude=$code --exclude=doxygen  

  fi

done # < /data/buildbot/500sample.txt

