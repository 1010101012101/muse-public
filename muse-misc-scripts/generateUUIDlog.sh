#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

#  Given a path of project write out to a file in the format necessary for ES index script


if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to copy to the SAN is required."
    exit 4
fi

src=$1
output="corpus.csv"

count=1

 while read file; do
    echo "working on: $file"
    uid=$(echo $file| cut -d "," -f 1)
    path=$(echo $file | rev | cut -d "/" -f 2-11 | rev)
    #echo "   $size,$path"
    echo "  /$path,$uid" >> $output
 done < $src 
 echo ""






