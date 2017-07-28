#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
newcount=0
# total number of gc project's crawled (grab from lastDownload.dat)
count=76642  #36607
# total num of project's downloaded (grab from lastDownload.dat)
downloaded=70375 #33359
path=/data/googlecode2
file=~/google-crawler/gcProjectInfo2012-Nov-trim2.dat
available=$(wc -l $file | cut -d " " -f 1 )
IFS=$'\t'

if [ -f $file ]
then
  #read through the projects file parsing each line
  while read line
  do

    tokens=( $line )
    echo "Starting project $count: " ${tokens[0]} " " ${tokens[5]}

    uuid=$(uuid)
    echo "  uuid: $uuid"

    dest_path=$(echo "$path/${uuid:0:1}/${uuid:1:1}/${uuid:2:1}/${uuid:3:1}/${uuid:4:1}/${uuid:5:1}/${uuid:6:1}/${uuid:7:1}/$uuid")
    echo "To: $dest_path"

 
    echo "  svn checkout http://${tokens[0]}.googlecode.com/svn/trunk/ $dest_path/latest"
    svn=$(svn checkout http://${tokens[0]}.googlecode.com/svn/trunk/ $dest_path/latest)
    if [[ ! -z "$svn" ]]
    then
      d=$((downloaded++))
      echo "  creating project properties"
      echo -e $count "\t" $uuid "\t" ${tokens[0]} "\t" ${tokens[5]} >> $dest_path/project.properties
    fi
    echo "Donwloaded on Muse3: " $((newcount++))
    echo "Total Downloaded: $downloaded " Crawled: " $((count++)) " Available: " $available"
    echo -e $downloaded "\t" $count "\t" ${tokens[0]} > lastProject.dat
    echo ""

  done < "$file" 

fi
