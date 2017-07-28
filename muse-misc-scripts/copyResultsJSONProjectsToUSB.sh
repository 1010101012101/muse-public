#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# Given a search results json file from our search site,
# copy all projects conntained therein in to a mount drive 


count=1
src_path=/data/corpus/
dest_path=/media/USBdrive/SRI/


if [ ! -d $dest_path ]; then

   echo "destination directory doesn't exist: $dest_path"
   exit
fi

paths=$(jq  -r '.results[].path' java-results.json)

for path in $paths
do

    if [ -d $dest_path ]; then

      dpath=$(echo $path | rev | cut -d "/" -f 2- | rev)
      uid=$(echo $dpath | rev | cut -d "/" -f 1 | rev)
 #     echo "copied $((count++)) : $xtfs_path$path"
      mkdir -p $dest_path$dpath/
      cd $src_path$dpath
      #echo "cp -fR $xtfs_path$path $dest_path$dpath/"
      echo "$((count++)): tar -czf $dest_path$dpath/$uid.tgz $src_path$dpath"
      tar -czf $dest_path$dpath/$uid.tgz *
#      rsync -av -P $xtfs_path$path $dest_path$dpath/
      echo "-----------------------------" 
    fi   
done
