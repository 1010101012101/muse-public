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

  index=$project/index.json
  indextmp=$project/index.json.tmp
  if [  -f $index ]; then

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    repo=$(jq -r .repo $project/index.json)

    if [ -f $project/$repo/commits.json ]; then
       latest=$(jq -r .[0].sha $project/$repo/commits.json | head -n 1)
       echo "  latest commit: $latest"
       jq '. |= .+ {"code_versions": [ {"version": "1", "commit_revision": "'$latest'"}]}' $index > $indextmp
       mv $indextmp $index
    fi

    echo ""
  fi
done
#done < ~/Nathan/newSFs.log

