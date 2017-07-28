#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

count=0
repo="java2s"
path="/data/java2s/"
index=""
new_date="2015-04-29T05:01:49.938Z"
# Extract source from latest
find $path -maxdepth 10  -mindepth 10 -type d |

while read foldername
do
   proj_path=$(echo $foldername | rev | cut -d "/" -f 2- | rev)
   proj_name=$(echo $foldername | rev | cut -d "/" -f 1 | rev)

   if [ "$proj_name" != "java2s" ]; then
   uuid=$(echo $foldername | rev | cut -d "/" -f 2 | rev)
   uid=$(uuid)
   category=$(echo $proj_name | cut -c 1)

   echo $((count++)) Working on: $proj_name
   echo $proj_path
   echo $uuid
   echo "---------------"
   index=$proj_path/index.json

# check to see if index.json already exists

  echo "{}" > $index

  cat $index | jq '. + {"corpus_release": "2.0"}' | jq '. + {"site_specific_id": "'$uid'"}' | jq '. + {"name": "'$proj_name'"}' |  jq '. + {"repo": "'$repo'"}' |  jq '. + {"site": "'$repo'"}' |  jq '. + {"uuid": "'$uuid'"}' | jq '. + {"crawler_metadata": ["./'$repo'/info.json", "./'$repo'/languages.json"]}' | jq '. + {"crawled_date": "'$new_date'"}' > $proj_path/tmp.index.json
   rm -fr $proj_path/index2.json
   mv $proj_path/tmp.index.json $index

  # info.json
  info=$proj_path/$repo/info.json
  mkdir -p $proj_path/$repo

  echo "{}" > $info
  cat $info | jq '. + {"name": "'$proj_name'"}' | jq '. + {"id": "'$uid'"}' | jq '. + {"full_name": "'$proj_name'"}' |  jq '. + {"description": ""}' |  jq '. + {"language": "Java"}' |  jq '. + {"html_url": "http://www.java2s.com/Code/Jar/'$category'/'$proj_name'.htm"}' | jq '. + {"created_at": "'$new_date'"}' > $proj_path/$repo/tmp.info.json
  mv $proj_path/$repo/tmp.info.json $info

  # languages.json
  echo '{"Java": 0}' > $proj_path/$repo/languages.json
  fi
done

   # determine contents size
#   size=$(ls -lR  $foldername/content/ | grep '.java$' | awk '{total += $5} END {print total}')
#   echo " {\"Java\": $size}" >> $proj_path/$repo/languages.json

#   echo ""
#done
