#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# Must suplly last_project and uid to resume downloading from a certain project

uid='b15b6b0c-fd74-11e4-9002-549f3505b658'
last_project='jetty-jmx'
dest_path='/data/java2s/b/1/5/b/6/b/0/c/b15b6b0c-fd74-11e4-9002-549f3505b658/jetty-jmx'
count=1
file=/data/java2s/zipfile-final4
path="/data/java2s"
useragent="\"Mozilla/5.0 (X11; U; Linux i686; pl-PL; rv:1.9.0.2) Gecko/20121223 Ubuntu/9.25 (jaunty) Firefox/3.8\""
files=$(wc -l $file | cut -d " " -f 1 )

if [ -f $file ]
then
  # parsing each .jar.zip file
  while read jarzip
  do
  
    echo "Starting jar: $jarzip" 
    echo ""
    project=$(echo $jarzip | rev | cut -d "/" -f 2 | rev)
    zipname=$(echo $jarzip | rev | cut -d "/" -f 1 | rev)
    echo "  Project: $project"

    if [ "$last_project" != "$project" ]
    then
      echo "   is a NEW project ..."
      uid=$(uuid)
      dest_path=$(echo "$path/${uid:0:1}/${uid:1:1}/${uid:2:1}/${uid:3:1}/${uid:4:1}/${uid:5:1}/${uid:6:1}/${uid:7:1}/$uid/$project")
      echo "  dest_path: " $dest_path
      mkdir -p $dest_path
    fi
    echo ""


    #echo "wget --limit-rate=500k -P $path $jarzip"
    wget --limit-rate=500k -nc -P $dest_path $jarzip 
    echo ""
    echo "Unzip jarfile..."
    unzip $dest_path/$zipname -d $dest_path
    echo ""
    echo "$count  $project $uid  $zipname" > /data/java2s/lastZipDownloaded.dat
    # remove zipfile after unzipped
    rm -fr $dest_path/$zipname 

    last_project=$project

    echo "completed $((count++)) of $files"
    echo "-------------------------------------------"
    echo ""

  done < "$file" 

fi
