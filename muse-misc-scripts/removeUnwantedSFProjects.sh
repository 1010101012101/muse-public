#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

count=11
pcount=0

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects is required."
    exit 4
fi

src_path=$1


find $src_path -maxdepth 9 -mindepth 9 -type d |

while read foldername
do

   if [ -f $foldername/index.json ]; then

      repo=$(jq -r .repo $foldername/index.json)
      uid=$(jq -r .uuid $foldername/index.json)
      id=$(jq -r .site_specific_id $foldername/index.json)
 
      if [ "$repo" != "null" ]; then
         if [ ! -f $foldername/$repo/languages.json ]; then
            echo "No languages.json $((count++))-----REMOVING PROJECT------"
            rm -fr $foldername 
#            echo "redis-cli -n 3 DEL \"uuid-to-id:$repo:$uid\""
            #redis-cli -n 3 DEL "uuid-to-id:$repo:$uid"
#            echo "redis-cli -n 3 DEL \"id-to-uuid:$repo:$id\""
            #redis-cli -n 3 DEL "id-to-uuid:$repo:$id"

         else
            langs=$(jq . $foldername/$repo/languages.json)
            if [ "$langs" == "{}" ]; then
               echo "Empty languages.json $((count++))-----REMOVING PROJECT------"
               rm -fr $foldername 
            else
              # project iwth src code exists
	      # add to redis
              redis-cli -n 3 SET "uuid-to-id:$repo:$uid" "$id"
              echo "redis-cli -n 3 ADD \"id-to-uuid:$repo:$id\" \"$uid\""
              redis-cli -n 3 SET "id-to-uuid:$repo:$id" "$uid"
	    fi

         fi
      fi
   fi 
done
