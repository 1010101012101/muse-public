#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

dest=/data/corpus_8tof/googlecode_all
src=/data/googlecode
count=1

find $src -maxdepth 9 -mindepth 9 -type d | 

while read project  
do

   echo "Count: $((count++))"
   path=$(echo $project | rev | cut -d "/" -f -9 | rev) 
   echo "   from: $src/$path/*"

   echo "   to: $dest/$path/"
#   rm -fr $dest_path

   mkdir -p $dest/$path
   cp -fr $src/$path/* $dest/$path/

   echo ""
done

