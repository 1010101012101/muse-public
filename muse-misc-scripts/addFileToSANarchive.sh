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
san1="/data/corpus_0to7"
san2="/data/corpus_8tof"
dest=""

#if [[ $# != 1 ]]; then
#    echo "$0: A path to the projects you wish to copy to the SAN is required."
#    exit 4
#fi

#src=$1

src="/data/grammatech/grammatechMakes/forced_build_makefiles/"

#Loop through all projects
find $src -type f -name *.Makefile  |

while read project
do
#    echo $project
#    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev | cut -d "." -f 1 )
    mfile=$(echo $project | rev | cut -d "/" -f 1 | rev )
    folder=$(echo $project | rev | cut -d "/" -f 2- | rev )
#    echo $uid
    code_tgz=$uid"_code.tgz"
    code_targz=$uid"_code.tar.gz"
    code_tar=$uid"_code.tar"

    if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
       dest=$san1
    else
       dest=$san2
    fi 
    path="$dest/"${uid:0:1}"/"${uid:1:1}"/"${uid:2:1}"/"${uid:3:1}"/"${uid:4:1}"/"${uid:5:1}"/"${uid:6:1}"/"${uid:7:1}"/$uid" 

    if [ -f $path/index.json ]; then
    
       echo "Working: $path"
       hasCode=$( jq -r 'has("code")' $path/index.json)
       if [ "$hasCode" = true ]; then

          code=$( jq -r .code $path/index.json)
          code=$( echo $code | rev | cut -d "/" -f 1 | rev )
          built=$( jq -r .buildStatus $path/filter.json)

          if [ "$built" == "failure" ]; then
            echo " $((count++)) projects not built"
          fi
         
          # uncompress tgz
          cd $path 
          gzip -d $code_tgz
       
          # copy new mfile to tmp location (mirror were you want it)
          mkdir -p ~/tmp/$code
          cp -fr $project ~/tmp/$code/
          chown muse:muse ~/tmp/$code/*
          cd ~/tmp/

          # append file to archive
          echo "  adding: $code/$mfile"
          echo "  to: $path/$code_tgz"
          tar --append --file $path/$code_tar $code/$mfile 

	  # zip archive back up
          gzip $path/$code_tar
          mv $path/$code_targz $path/$code_tgz

          # remove tmp folders
          rm -fr ~/tmp/*
          echo "-----------------------------" 
       fi
    fi

#      echo "-----------------------------" 
#    fi   
done
