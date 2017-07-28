#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

#  Extract all files from a project along with their associated size in bytes 
#  writing to "file_sizes.txt"

overwrite="false" # overwrite json file if already exists
one="false"  # only run on a single program

while [[ $# > 1 ]]
do
key="$1"

# get cmd line args
case $key in
    -one)
    one="true"
    shift
    ;;
    -o)
    overwrite="true"
    shift
    ;;
    *)
   # unknown option
    ;;
esac
done

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to run over is required."
    exit 4
fi

path=$1

count=1

# temp folder to extract archives into if using SAN
if [ $one == "false" ]; then
  if [[ $path == *"0to7"* ]]; then
    tmp="/home/muse/extractors/file_sizes/tmp07/"
  else
    tmp="/home/muse/extractors/file_sizes/tmp08/"
  fi
else
  if [[ $path == *"0to7"* ]]; then
    tmp="/home/muse/extractors/tmp07/"
  else
    tmp="/home/muse/extractors/tmp8f/"
  fi
fi
mkdir -p $tmp
tmpList=$tmp"/tarlist.txt"
echo "Using tmp folder: $tmp"

if [ $one == "true" ]; then
   src="echo $path"
else
   src="find $path -mindepth 9 -maxdepth 9 -type d"
fi

echo "starting file sizes extractor..."
#Loop through all projects
$src |
while read project
do
  echo "Working on $((count++)) project: $project ================="

  if [  -f $project/index.json ]; then

    uid=$( cat $project/index.json | jq -r .uuid )
    archive=$uid"_code.tgz"
    output=$project/file_sizes.txt
    if [ -f $output ]; then
       echo "already exists, skipping.."
       continue
    fi
    
    # check to ensure src code location was specified in index.json
    if [ -f $project/$archive ]; then
         echo "" > $output

         echo "tar tzvf $project/$archive > $tmpList"
         tar tzvf $project/$archive | grep -v '/$' > $tmpList

         while read file; do
           size=$(echo $file| cut -d " " -f 3)
           path=$(echo $file | cut -d " " -f 6)
           #echo "   $size,$path"
           echo "$size,$path" >> $output
         done < $tmpList
    fi
    rm -fr $tmp/*
  fi
  echo ""
done






