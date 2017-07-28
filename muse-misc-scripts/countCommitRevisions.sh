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
revisions=0
count1=0

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to count is required."
    exit 4
fi

src=$1
log='corpus8f_revisions2.log'
echo "" $log

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |

while read project
do

  index=$project/index.json
  if [  -f $index ]; then
    echo "Working on $((count++)) project: $project ================="

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    repo=$(jq -r .repo $project/index.json)
    code=$(jq -r .code $project/index.json)
    commits=1
    if [ -f $project/$repo/commits.json ]; then
       commits=$(jq -r .[].sha $project/$repo/commits.json | wc -l)
       revisions=$((revisions + commits))
    else
       count1=$((count1 + 1))
       if  [ "$code" != "null" ]; then      
          revisions=$((revisions + 1))
       fi
    fi
    echo "$uid,$commits" >> $log
    echo "  revisions = $revisions"
    echo ""
  fi
done

echo "only 1 rev: $count1"
#done < ~/Nathan/newSFs.log

