#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# remove subset of paths from redis queue that contain sourceforge 

count=1

#Loop through all build projects

list=$(redis-cli -h muse2-int -p 12345 LRANGE "queue:muse-project-paths" 0 -1)

for path in $list
do

    echo "Working on $((count++)) project: $path"
    if [[ "$path" == *"sourceforge"* ]]; then
       echo "FOUND"
       redis-cli -h muse2-int -p 12345 LREM "queue:muse-project-paths" 1 $path
       
    fi
done

