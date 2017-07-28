#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# create a redis set of built projects

count=1

#Loop through all build projects
find /data/build -maxdepth 9 -mindepth 9 -type d |

while read project
do
  if [ -f $project/build.json ]; then
    echo "Working on $((count++)) project: $project ================="
#   path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    redis-cli -h muse2-int -p 12345 SADD "set:NEWbuiltProjects" "$uid"
  fi
  echo ""
done


#Loop through all build projects
find /data/builder_SAN/output -maxdepth 9 -mindepth 9 -type d |

while read project
do
  if [ -f $project/build.json ]; then
    echo "Working on $((count++)) project: $project ================="
#   path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    redis-cli -h muse2-int -p 12345 SADD "set:NEWbuiltProjects" "$uid"
  fi
  echo ""
done

