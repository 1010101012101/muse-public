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
file=~/zipfile.test
path="/data/java2s"
useragent="\"Mozilla/5.0 (X11; U; Linux i686; pl-PL; rv:1.9.0.2) Gecko/20121223 Ubuntu/9.25 (jaunty) Firefox/3.8\""
files=$(wc -l $file | cut -d " " -f 1 )

if [ -f $file ]
then
  # parsing each .jar.zip file
  while read jarzip
  do
  
    echo "Starting jar: $jarzip" 

    project=$(echo $jarzip | rev | cut -d "/" -f 2 | rev)
    echo "Project name: $project"

    mkdir -p $path/$project

    #echo "wget --limit-rate=500k -P $path $jarzip"
    wget --limit-rate=500k -nc -P $path/$project $jarzip 
 
    echo "completed $((count++)) of $files"
    echo ""

  done < "$file" 

fi
