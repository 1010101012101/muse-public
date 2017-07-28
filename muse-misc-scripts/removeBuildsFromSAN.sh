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
pcount=0

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects is required."
    exit 4
fi

src_path=$1


find $src_path -maxdepth 9 -mindepth 9 -type d |

while read project 
do
    ((pcount++))
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    build_tgz=$uid"_build.tgz"

   if [ -f $project/$build_tgz ]; then
      echo "$((count++)) of $pcount rm -fr $project/$build_tgz"
      rm -fr $project/$build_tgz
   fi 
done
