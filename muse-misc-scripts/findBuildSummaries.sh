#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

src=/data/build
log='buildSummaries.log'
echo "" > $log
count=1

find $src -mindepth 10 -maxdepth 10 -type f -name "build*.json" | 

while read file  
do

   echo "Working on build: $((count++)) $file"
   echo $file >> $log
   echo ""
done

