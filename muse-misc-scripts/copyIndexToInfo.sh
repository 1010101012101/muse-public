#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

#Takes a search results json file from our search web interface and parses out project paths
# copies all the projects therein to a new directory or drive

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


  #read through the projects file parsing each line
  while read project; 
  do

    uid2=$(echo $project | rev | cut -d "/" -f 1 | rev )
    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev )
    if [ -f $project/index.json ]; then
    echo "Working on: $((count++)): $project ====="


      id=$(jq -r .site_specific_id $project/index.json)
      date=$(jq -r .crawled_date $project/index.json)
      name=$(jq -r .name $project/index.json)
      echo $name
      uid=$(jq -r .uuid $project/index.json)
      repo=$(jq -r .repo $project/index.json)
      sname=$(echo $name | cut -d "/" -f 2)
      echo $sname

      infojson=$project/$repo/info.json
      url="http://www.github.com/"$name
      echo $url 

      if [ ! -f $infojson ]; then
         # construct info.json
         echo $project >> $log
        # echo ""
        # echo "{\"id\":\"$id\",\"html_url\":\"$url\",\"name\":\"$sname\",\"full_name\":\"$name\",\"description\":\"\",\"created_at\":\"$date\",\"uuid\":\"$uid\"}" > $infojson

      fi
    else
      if [ ! -d $project ]; then 
        echo "/data/corpus-xtfsvol/"$path 
        if [ -d "/data/corpus-xtfsvol/"$path ]; then
          echo " project no longer exists needs to be removed"
        fi
         echo $uid2 >> $rlog
      fi
    fi
  done <$input 

fi
