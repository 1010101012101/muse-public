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

dest1="/data/corpus_8tof"
dest3="/data/corpus_0to7"
xtfs="/data/corpus-xtfsvol"
dest=$dest1


while read project; do
  
  uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
  path="${uid:0:1}/${uid:1:1}/${uid:2:1}/${uid:3:1}/${uid:4:1}/${uid:5:1}/${uid:6:1}/${uid:7:1}/$uid"
  codetgz=$project"/"$uid"_code.tgz"
  echo $codetgz

    if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
       dest=$dest3
    else
       dest=$dest1
    fi

  
  if [ -f $codetgz ]; then
    built=$(jq -r .buildStatus $dest/$path/filter.json)
    echo $built
    if [[ "$built" == "success" ]]; then
       echo "$((++count)) $built" 
    
    elif [[ "$built" == "failure" ]]; then
       echo "$((++countf)) $built"
    else
       echo "$((++countno)) $builtt"
    fi
    echo "python -mdcharvest.corpusTools.submitProject --project=file://$codetgz --forceClangArgs=\"-O0\" --loadES=\"38.100.20.211\" --builder selectAndBuild --submit --config /leit/buildbot/dcharvest/configs/LocalConfig.cfg"
  fi


done <$src
