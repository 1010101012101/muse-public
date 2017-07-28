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
xtfs="/data/corpus-xtfsvol"
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

    if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
       dest=$dest3
    else
       dest=$dest1
    fi

    # skip any projects that already exist; check for empty code archives and remove
    if [ -f $dest/$path/index.json ]; then
       echo "skipping project..."
       continue
    fi 

    echo "  mkdir -p $dest/$path/"
    mkdir -p $dest/$path/

    # Copy doxygen json if exists
    if [ -f $project/doxygen/doxygen.json ]; then
#       echo "  cp -fr $project/doxygen/ $dest/$path"
       cp -fr $project/doxygen/ $dest/$path
    fi

    # Copy over metadata folder
    repo=$( cat $project/index.json | jq -r .repo)
    if [[ "$repo" != "null" ]]; then
       echo "   copying metadata folder..."
       cp -fr $project/$repo $dest/$path/
    fi

    # Copy over top level json files needed for indexing
#    echo "  cp -fr $project/index.json $dest/$path/"
    cp -fr $project/index.json $dest/$path/
#    echo "  cp -fr $project/filter.json $dest/$path/"
    cp -fr $project/filter.json $dest/$path/


    # Archive the metadata for each project, if exists
    echo "   tar czf $dest/$path/$meta_tgz *.txt *.json $repo doxygen/"
    cd $project

    if [ -d $project/doxygen ]; then
      tar czf $dest/$path/$meta_tgz *.txt *.json $repo doxygen/
    else
      tar czf $dest/$path/$meta_tgz *.txt *.json $repo
    fi



    # Copy over any build archives if exists on xtfs vol
#    if [ -d $xtfs/$path/buildResults ]; then
#       echo "   copying build tgz to SAN"
#       su -c "cp $xtfs/$path/buildResults/* $dest/$path/" -s /bin/sh muse
#    fi

    # Archive the latest src of each project, if exists
    code=$( cat $project/index.json | jq -r .code)
    if [[ "$code" != "null" ]]; then
       code=$(echo $code | cut -c 3-)
       echo "   tar czf $dest/$path/$code_tgz $code"
       cd $project
       tar czf $dest/$path/$code_tgz $code

       # Archive everything else in project except latest src, and metadata files used for indexing
       echo "   tar czvf $dest/$path/$uid.tgz --exclude=index.json --exclude=filter.json --exclude=doxygen --exclude=$code --exclude=$repo ."
       tar czf $dest/$path/$uid.tgz --exclude=index.json --exclude=filter.json --exclude=doxygen --exclude=$code --exclude=$repo . 

    else

       # Archive everything else in project except metadata files used for indexing
        echo "   tar czvf $dest/$path/$uid.tgz --exclude=index.json --exclude=filter.json --exclude=doxygen --exclude=$repo ." 
        cd $project
        tar czf $dest/$path/$uid.tgz --exclude=index.json --exclude=filter.json --exclude=doxygen --exclude=$repo . 
    fi

    echo ""
  fi
done
#done < ~/Nathan/newSFs.log

