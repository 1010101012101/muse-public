#! /bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
#  Convert Subversions Commits.xml file into a JSON file that fits the standards of github

count=0

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects is required."
    exit 4
fi

src=$1

find $src -mindepth 9 -maxdepth 9 -type d  |

while read project
do

   echo "Working on $((count++)) project: $project ================="

  if [  -f $project/index.json ]; then

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)

    if [ -f $project/commits.xml ]; then

       xml2json -t xml2json -o $project/commits.json.tmp $project/commits.xml --strip_text

       if [ -f $project/commits.json.tmp ]; then
          input=$project/commits.json.tmp
          output=$project/commits.json
       
          num=$(jq '.log.logentry | length' $input)
          echo $num

          echo "[" > $output
          for (( i=0; i<$num; i++ ))
          do
   		msg=$(cat $input  | jq -r '.log.logentry['${i}'].msg')
#   		echo "  " $msg   
   		author=$(cat $input  | jq -r '.log.logentry['${i}'].author')
 #  		echo $author
   		date=$(cat $input  | jq -r '.log.logentry['${i}'].date')
  # 		echo $date
   		id=$(cat $input  | sed 's/@revision/revision/g' | jq -r '.log.logentry['${i}'].revision')
   #		echo $id

   		if [ "$i" -eq "$(($num-1))" ]; then 
     			echo "{\"sha\": \"$id\",\"commit\":{\"author\":{\"name\": \"$author\", \"date\": \"$date\"}, \"message\": \"$msg\"}}" >> $output
   		else
     			echo "{\"sha\": \"$id\",\"commit\":{\"author\":{\"name\": \"$author\", \"date\": \"$date\"}, \"message\": \"$msg\"}}," >> $output
   		fi
   		
	#	jq '. + {"sha": "$id","commit":{"author":{"name": "$author", "date": "$date"}, "message": "$msg"}}' $output
   	#	mv $outtemp $output
   
	  done

          echo "]" >> $output
          rm -fr $input
          cat $output | tr -cd '\40-\176' | jq . > $output
       fi
     fi
  fi
done
