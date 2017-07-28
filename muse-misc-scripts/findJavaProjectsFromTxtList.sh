#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Copy projects from src path into the SAN volume 
# just needt to supply src path

count=1
dest1="/data/corpus_8tof"
dest3="/data/corpus_0to7"
xtfs="/data/corpus-xtfsvol"
dest=$dest1

out=phase2_java_projects.log

#Loop through all projects
#find $src -mindepth 9 -maxdepth 9 -type d  |
echo "" > $out

while read project
do

  if [  -f $project/github/languages.json ]; then
   echo "Working on $((count++)) project: $project ================="

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    java=$( jq .Java $project/github/languages.json)
 
    if [[ "$java" != "null" ]]; then
      if [[ "$java" > 0 ]]; then
        echo "found one:  $java"
        echo $project >> $out
      fi
    fi
    # Copy over metadata folder
  fi


    # Archive the latest src of each project, if exists
done < /home/muse/scripts-util/directedPH2all.txt

