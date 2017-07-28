#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

null='null'
count=1


if [[ $# != 1 ]]; then
    echo "$0: A path to the corpus you wish to update redis keys for is required."
    exit 4
fi

path=$1


repo="github"  # default
find $path -maxdepth 9 -mindepth 9  -type d |

while read project 
do
#   project=$(echo $foldername) # | rev | cut -d "/" -f 2- | rev)
   index=$project/index.json 
   echo "Working on $((count++)) project"

   if [ -f $index ]
   then

       uid=$(cat $index | jq -r .uuid)
       sid=$(cat $index | jq -r .site_specific_id)
       repo=$(cat $index | jq -r .repo)
#	echo $uid
       if [ ! -z "$uid" ] && [ "$uid" != "null" ]; then
         if [ ! -z "$sid" ] && [ "$sid" != "null" ]; then
             echo "Create Redis Keys..."
             echo "redis-cli -n 3 SET \"id-to-uuid:$repo:$sid $uid\""
             echo "redis-cli -n 3 SET \"uuid-to-id:$repo:$uid $sid\""
                        
             redis-cli -n 3 SET "id-to-uuid:$repo:$sid" "$uid"
             redis-cli -n 3 SET "uuid-to-id:$repo:$uid" "$sid"

# remove accidental redis keys            
#             redis-cli -n 3 DEL "id-to-uuid:$sid" 
#             redis-cli -n 3 DEL "uuid-to-id:$uid" 
         fi
       fi
   else
 		echo "$index -- no index.json present"
   fi
done
