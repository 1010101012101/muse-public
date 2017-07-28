#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# loop thru and submit projects to buildbot

count=0
countno=0
countf=0

if [[ $# != 1 ]]; then
    echo "$0: A text file containing the list of projects you wish to build."
    exit 4
fi

src=$1
out="buildbotComparison.log"
echo "" > $out
dest="/data/buildbot"
dest2="/nfsbuild"

draper=0
leidos=0

while read project; do
  
  uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
  path="${uid:0:1}/${uid:1:1}/${uid:2:1}/${uid:3:1}/${uid:4:1}/${uid:5:1}/${uid:6:1}/${uid:7:1}/$uid"
  echo $uid

  if [ -f $project/github/info.json ]; then
     html=$(jq -r .html_url $project/github/info.json)
  fi

draper=0
leidos=0
draperStr="failed"
leidosStr="failed"
  if [ -d $dest/$path ]; then
    archive=$(find $dest/$path/ -type f -name *.tgz | head -1)

    if [ -f $archive ]; then
      numllvm=$(tar tzvf $archive | grep -c '\llvm.o$')
      numo=$(tar tzvf $archive | grep -c '\.o$')

      if [[ "$numo" -gt "$numllvm" ]]; then
           echo "  success : Draper"
           draper=1
           draperStr="success"
      else
           echo "  failed : Draper"
           draper=0
           draperStr="failed"
      fi
#      if [[ "$numllvm" -eq "$numo" ]]; then
#         echo "failed:  $((++countf))"
#      else
#         echo "success: $((++countno))"
#      fi
    else
       draperStr="failed"
#      echo "  failed : Draper"
    fi
  else
#   echo "  failed : Draper"
    draperStr="failed"
  fi
  if [ -f $dest2/$path/build.json ]; then
     bstatus=$(jq -r .buildStatus $dest2/$path/build.json)

     archive=$(find $dest2/$path/ -type f -name *.tgz | head -1)

#    echo $archive

     if [ -f $archive ]; then
       #echo "$((++count)) found"
         numoo=$(tar tzvf $archive | grep -c '\.o$')
          
         if [[ "$numoo" -gt 0 ]]; then
            echo "  success : Leidos"
            leidos=1
            leidosStr="success"
            #echo $((++countno)) found objs
         else
            echo "  failed : Leidos"
            leidos=0
            leidosStr="failed"
         fi
     fi

#     if [[ "$draper" -eq 0 ]] && [[ "$leidos" -eq 1 ]]; then
#       echo " leidos better $((++count))"
#     fi
#     if [[ "$draper" -eq 1 ]] && [[ "$leidos" -eq 0 ]]; then
#       echo " draper better $((++countno))"
#     fi
#     if [[ "$bstatus" == "success" ]]; then
#        echo $((++count))
#     fi 
#     if [[ "$bstatus" == "partial" ]]; then
#        echo $((++count))
#     fi 

  fi
  echo "$uid,$html,$leidosStr,$draperStr" >> $out
done <$src
