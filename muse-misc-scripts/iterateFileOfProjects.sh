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

out=corpusRepos.log

#Loop through all projects
#find $src -mindepth 9 -maxdepth 9 -type d  |
echo "" > $out

while read project
do

  if [  -f $project/github/info.json ]; then
   echo "Working on $((count++)) project: $project ================="

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    html=$(jq -r .html_url $project/github/info.json)
    echo "$uid,$html,"  >> $out

    # Copy over metadata folder
  fi


    # Archive the latest src of each project, if exists
done < /data/buildbot/500sample.txt

