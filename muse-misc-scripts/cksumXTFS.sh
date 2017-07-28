#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

src=/data/corpus-xtfsvol
dest=/home/muse
version=4  # version of xtfs corpus
log=$dest/"MUSE-corpus-V"$version"_2.txt"
echo $log
count=1

find $src -mindepth 9 -type f | 

while read file  
do

   echo "XTFS File Count: $((count++)) $file"
   cksum $file >> $log

   echo ""
done

