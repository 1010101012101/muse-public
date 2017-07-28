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
# copies all the projects therein from xtfs mount to a new destination folder

count=1  

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
  echo "Usage: ./copyProjectsFromJSON jsonFile xtfs_mount destination_folder"
  exit -1
fi
jsonfile=$1 
xtfs_mount=$2 
dest=$3 

if [ -f $jsonfile ]
then

  paths=$(jq -r .results[].path $jsonfile)

  #read through the projects file parsing each line
  for path in $paths 
  do
    # grab project path
    path=$(echo $path | rev | cut -d "/" -f 2- | rev)

    echo "Working on: $((count++)) =========="

    # skip if destination folder exists
    if [ ! -d $dest/$path ]; then

       mkdir -p $dest/$path
       echo "   rsync -r $xtfs_mount/$path/* $dest/$path/"
       rsync -r $xtfs_mount/$path/* $dest/$path/
    else
       echo "   already exists, skipping:   $dest/$path"
    fi

  done
fi
