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
log=metadata.log

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to extract topics is required."
    exit 4
fi

src=$1

dest=$dest1

dest3="/data/corpus_0to7"
dest2="/data/corpus_8tof"
dest=$src # dest2

echo "projects with unknown archive file types" > $log

find $src -maxdepth 9 -mindepth 9 -type d | 



while read project  
do

   echo "Working on $((count++)) project: $project"
    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)

    if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
       dest=$dest3
    else
       dest=$dest2
    fi

    dest=$src ### remove

    if [ -d $dest/$path ]; then
   topicsjson=$dest/$path/topics.txt
   echo "  $topicsjson"
   
#   if [ ! -f $topicsjson ]; then

   if [ -f $project/metadata.json ]; then

      if [ ! -s $project/metadata.json ]; then
         echo "empty metadata"
         echo ""
         continue
      fi

      topic1=$(jq -r .categories.topic[0].fullpath $project/metadata.json)
      topic2=$(jq -r .categories.topic[1].fullpath $project/metadata.json)
      topic3=$(jq -r .categories.topic[2].fullpath $project/metadata.json)
      topic4=$(jq -r .categories.topic[3].fullpath $project/metadata.json)
      topic5=$(jq -r .categories.topic[4].fullpath $project/metadata.json)

#      proj_id="null"
#      proj_id=$(jq -r .tools[0].sourceforge_group_id $project/metadata.json)
#      if [ $proj_id == "null" ]; then


      echo "" > $topicsjson

      if [ "$topic1" != "null" ]; then
        echo "$topic1" > $topicsjson
      fi
      if [ "$topic2" != "null" ]; then
        echo "$topic2" >> $topicsjson
      fi
      if [ "$topic3" != "null" ]; then
        echo "$topic3" >> $topicsjson
      fi
      if [ "$topic4" != "null" ]; then
        echo "$topic4" >> $topicsjson
      fi
      if [ "$topic5" != "null" ]; then
        echo "$topic5" >> $topicsjson
      fi

   fi

#   else

#     echo "already generated. skipping..."
#   fi

#   rm -fr $dest_path

   fi
   echo ""
done

