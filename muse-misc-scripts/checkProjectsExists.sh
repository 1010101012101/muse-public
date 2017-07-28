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

if [ -z "$1" ]
then
  echo "Usage: ./copyIndexToInfo fileListofProjs"
  exit -1
fi
input=$1


log='index321.txt'
rlog='removeindex321.txt'
echo "" > $log
echo "" > $rlog

if [ -f $input ]
then



  while read file  
  do

   #echo "Working on: $((count++)) $file"
   echo ""
   if [ -f $file/index.json ]; then
     echo "found: $((count++)) $file"
   fi

  done <$input
fi

