#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

#Takes a search results json file from our search web interface and parses out project paths
# copies all the projects therein to a new directory or drive

count=1  

if [ -z "$1" ] || [ -z "$2" ]
then
  echo "Usage: ./copyProjectsFromJSON jsonFile destinationFile"
  exit -1
fi
jsonfile=$1 #'/home/muse/muse-search-results-2015-12-01T00_11_32.130Z.json'
xtfs_mount=$2 # /data/corpus-xtfs/
dest_path=$3 #/mnt/rice/muse-c-corpus/

echo "" > $log

if [ -f $file ]
then

  paths=$(jq -r .results[].path $file)

  #read through the projects file parsing each line
  for path in $paths 
  do
    path=$(echo $path | rev | cut -d "/" -f 2- | rev)

    echo "Working on: $((count++)) =========="

    uid=$(echo $path | rev | cut -d "/" -f 1 | rev)



   # if [ ! -d $dest$path ]; then

       #mkdir -p $dest$path
       echo "cp -fr $xtfs_mount/$path $dest_path/$path"
      # rsync -r $src$path/* $dest$path/
    #else
    #   echo "   already exists, skipping:   $dest$path"
    #fi

  done
fi
