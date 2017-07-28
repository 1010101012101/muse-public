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
if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to work is required."
    exit 4
fi

src=$1

#Loop through all projects
for project in $(find $src -maxdepth 9 -mindepth 9 -type d)
do

  echo "Working on $((count++)) project: $project ================="
#  path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
#  uid=$(echo $project | rev | cut -d "/" -f 1 | rev)

  svn --xml log $project/latest > $project/commits.xml

  echo ""
done

