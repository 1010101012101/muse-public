#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

src=/data/corpus_8tof/googlecode_all
count=1
repo=google
log=metadata.log

echo "projects with unknown archive file types" > $log

find $src -maxdepth 9 -mindepth 9 -type d | 

while read project  
do

   echo "Working on $((count++)) project: $project"
   path=$(echo $project | rev | cut -d "/" -f -9 | rev) 
   uid=$(echo $project | rev | cut -d "/" -f 1 | rev) 
   echo $uid

   indexjson=$project/index.json
   infojson=$project/$repo/info.json

   if [ ! -f $infojson ]; then

   if [ -f $project/project.properties ]; then

      if [ ! -s $project/project.properties ]; then
         echo "empty metadata"
         echo "" > $project/remove.me
         echo ""
         continue
      fi

      while read prop
      do
        echo $prop
        tokens=( $prop )
        total=${#tokens[@]}

        proj_id=${tokens[0]}
        name=${tokens[2]}
        shortname=${tokens[2]}
        description=$(echo $prop | cut -d " " -f 4-)
        url="https://code.google.com/archive/p/$name"
        date="2012-11-01T12:12:12Z"
      
      done < $project/project.properties

#       srch="$name[[:space:]]350"
#       echo $srch
#       sprops=$(cat gcProjectInfo2012-Nov.txt | grep $srch)
#       echo "Props: " $sprops

#      name=$(jq -r .name $project/metadata.json)
#      shortname=$(jq -r .shortname $project/metadata.json)
#      description=$(jq -r .short_description $project/metadata.json)
#      date=$(jq -r .creation_date $project/metadata.json)

      #if [ $language == "null" ]; then
        # echo "" > $project/nolanguage.defined
      #fi

#      url=$(jq -r .url $project/metadata.json)

#      if [ $date != "null" ]; then
#         date="${date}T12:00:00Z"
#      fi


#      echo "  $proj_id  $uid  $date  $language  $name"

      #construct index.json
      echo "{\"corpus_release\":\"2.0\",\"code\":\"./latest\", \"site_specific_id\":\"$proj_id\",\"repo\":\"$repo\",\"crawler_metadata\":[\"./$repo/info.json\",\"./$repo/languages.json\"],\"name\":\"$name\",\"site\":\"SourceForge\",\"crawled_date\":\"$date\",\"uuid\":\"$uid\"}" > $indexjson

     mkdir -p $project/$repo     
 
      # construct info.json
      echo "{\"id\":\"$proj_id\",\"html_url\":\"$url\",\"full_name\":\"$name\",\"description\":\"$description\",\"created_at\":\"$date\",\"uuid\":\"$uid\"}" > $infojson

   else   
      # no metadata file
      echo "No metadata"
#      echo "" > $project/remove.me
      #rm -fr $project/index.json

   fi

   else

     echo "already generated. skipping..."
   fi

#   rm -fr $dest_path


   echo ""
done

