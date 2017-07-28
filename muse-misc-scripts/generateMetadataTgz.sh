#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Archive all the metadata contained in each project
# metadata consists of .txt, .json, /doxygen files 

count=1

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to copy to the SAN is required."
    exit 4
fi

src=$1


#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |

while read project
do
   echo "Working on $((count++)) project: $project ================="

  if [  -f $project/index.json ]; then

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    repo=$(jq -r .repo $project/index.json)
    meta_tgz=$uid"_metadata.tgz"


    # skip any projects that already exist; check for empty code archives and remove
    if [ -f $project/$meta_tgz ]; then
       echo "skipping project..."
       continue
    fi 

    # Archive the latest src of each project, if exists
    echo "   tar czf $project/$meta_tgz *.txt *.json $repo doxygen/"
    cd $project
    
    if [ -d $project/doxygen ]; then
      tar czf $project/$meta_tgz *.txt *.json $repo doxygen/
    else 
      tar czf $project/$meta_tgz *.txt *.json $repo 
    fi

    echo ""
  fi
done
#done < ~/Nathan/newSFs.log

