#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

src=/data/corpus_8tof/sourceforge
count=1
repo=sourceforge
log=metadata.log

echo "projects with unknown archive file types" > $log

find $src -maxdepth 9 -mindepth 9 -type d | 

while read project  
do

   #echo "Working on $((count++)) project: $project"
   path=$(echo $project | rev | cut -d "/" -f -9 | rev) 
   uid=$(echo $project | rev | cut -d "/" -f 1 | rev) 
   #echo $uid

   indexjson=$project/index.json
   infojson=$project/$repo/info.json

   #if [ ! -f $infojson ]; then

   if [ -f $project/metadata.json ]; then

      if [ ! -s $project/metadata.json ]; then
         echo "empty metadata"
         echo "" > $project/remove.me
         echo ""
         continue
      fi

      if [ ! -d $project/latest ]; then
   echo "Working on $((count++)) project: $project"
      name=$(jq -r .name $project/metadata.json)
      shortname=$(jq -r .shortname $project/metadata.json)
      description=$(jq -r .short_description $project/metadata.json | tr -d '\t' | tr -d '\r' | tr -d '\n' | tr -d '"' | tr '\\' '/')
      date=$(jq -r .creation_date $project/metadata.json)
      language=$(jq -r .categories.language[0].fullname $project/metadata.json)
      #if [ $language == "null" ]; then
        # echo "" > $project/nolanguage.defined
      #fi
      proj_id="null"
      proj_id=$(jq -r .tools[0].sourceforge_group_id $project/metadata.json)
      if [ $proj_id == "null" ]; then
         proj_id=$(jq -r .tools[1].sourceforge_group_id $project/metadata.json)
         if [ $proj_id == "null" ]; then
            if [ -f $project/id.txt ]; then
               proj_id=$(cat $project/id.txt | cut -d "=" -f 2)
            fi
         fi
      fi

      url=$(jq -r .url $project/metadata.json)
      os=$(jq -r .categories.os[0].fullname $project/metadata.json)
      license=$(jq -r .categories.license[0].shortname $project/metadata.json)

      if [ $date != "null" ]; then
         date="${date}T12:00:00Z"
      fi
      
      archive="null"
      if [ $shortname != "null" ]; then
         archive="${shortname}.tar.bz2"
         #echo $archive
      fi


      # unpack src archive file, if exists
      if [ -f $project/$archive ]; then

      	compression=$(file $project/$archive)
      	compression=$(echo $compression | cut -d ":" -f 2 | cut -d " " -f 2 )
      	echo "  ----unpacking with: $compression----"

      	mkdir -p $project/latest
      	#cd $project/latest

      	if [ $compression == "gzip" ]; then
         echo "  tar tzf $project/$archive -C $project/latest"
         tar xzf $project/$archive -C $project/latest
      	 
      	elif [ $compression == "bzip2" ]; then
         echo "  tar tjf $project/$archive -C $project/latest"
         tar xjf $project/$archive -C $project/latest
      	 
      	elif [ $compression == "Zip" ]; then
         echo "  unzip $project/$archive -d $project/latest"
         unzip -qq -o $project/$archive -d $project/latest
      	 
      	elif [ $compression == "RAR" ]; then
         echo "  /usr/local/bin/unrar x $project/$archive $project/latest"
         /usr/local/bin/unrar x -o+ -inul $project/$archive $project/latest
      	 
      	elif [ $compression == "7-zip" ]; then
         echo "7za x $project/$archive -o$project/latest"
         7za x $project/$archive -o$project/latest

        else
	 echo $project >> $log
      	fi
         
      fi

      echo "  $proj_id  $uid  $date  $language  $name"

      #construct index.json
      echo "{\"corpus_release\":\"2.0\",\"code\":\"./latest\", \"site_specific_id\":\"$proj_id\",\"repo\":\"$repo\",\"crawler_metadata\":[\"./$repo/info.json\",\"./$repo/languages.json\"],\"name\":\"$name\",\"site\":\"SourceForge\",\"crawled_date\":\"$date\",\"uuid\":\"$uid\"}" > $indexjson

      mkdir -p $project/$repo     
 
      # construct info.json
      echo "{\"id\":\"$proj_id\",\"html_url\":\"$url\",\"full_name\":\"$name\",\"description\":\"$description\",\"language\":\"$language\",\"created_at\":\"$date\",\"uuid\":\"$uid\"}" > $infojson

#      if [ -d /data/corpus_0to7/$path/$repo ]; then
#        echo "  cp -fr $infojson /data/corpus_0to7/$path/$repo/"
#        cp -fr $infojson /data/corpus_0to7/$path/$repo/
#      fi
#      if [ -d /data/corpus_8tof/$path/$repo ]; then
#        echo "  cp -fr $infojson /data/corpus_8tof/$path/$repo/"
#        cp -fr $infojson /data/corpus_8tof/$path/$repo/
#      fi
 
     fi
   else   
      # no metadata file
      echo "No metadata"
      echo "" > $project/remove.me
      #rm -fr $project/index.json

   fi

   #else

   #  echo "already generated. skipping..."
   #fi

#   rm -fr $dest_path


   #echo ""
done

