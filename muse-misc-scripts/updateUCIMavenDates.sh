#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

dest=/data/crawler_SAN/cyberPhysicalNo
src=/data/corpus_0to7/
count=1
tmp="tmp/"
mkdir -p $tmp
find $src -maxdepth 10 -mindepth 10 -type d -name uciMaven | 

while read project  
do
   echo "Count: $((count++))"
   path=$(echo $project | rev | cut -d "/" -f 2- | rev) 
   echo $path 
   info=$project/info.json
   index=$path/index.json
   uid=$( cat $info | jq -r .uuid )
   new=$project/info.json.tmp
   archive="$path/$uid.tgz"
   echo $archive
 
   if [ -f $index ]; then
     version=$(jq -r .version $index)
     echo $version

    if [ -f $info ]; then
      if [ -f $archive ];then
           echo "  tar xzf $archive -C $tmp"
           tar xzf $archive -C $tmp
           echo $tmp/$version/jar.properties 
           if [ -f $tmp/$version/jar.properties ]; then
	      line=$(head -n 1 $tmp/$version/jar.properties)
              line=$(echo $line | cut -d "#" -f 2- )
              date=$("date -d '$line' +'%Y-%m-%dT%H:%M:%SZ'")
              echo $date 
#              jq '. + {"created_date": "'$date'"}' $info > $new
#             mv $new $info
           else
	       echo " no jar.properties"
           fi
      fi 
    fi
    
#    rm -fr $tmp/*
   fi 
   echo ""

done 


