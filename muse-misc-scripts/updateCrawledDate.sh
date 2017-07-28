#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Update crawled_date for uci projecdts 
# just needt to supply log of project paths

count=1

if [[ $# != 1 ]]; then
    echo "$0: A path to the corpus you wish to run extractor on is required."
    exit 4
fi
path=$1
echo "Running over: $path"

#Loop through all projects

find $path -mindepth 9 -maxdepth 9 -type d | 
while read project
do
    repo=$( cat $project/index.json | jq -r .repo )
    uid=$( cat $project/index.json | jq -r .uuid )
    site=$( cat $project/index.json | jq -r .site )
    meta=$( cat $project/index.json | jq  .crawler_metadata )
    index=$project/index.json
    new=$project/index.json.tmp
 
    if [ -f $index ]; then

    
      if [ "$repo" == "uci2010" ]; then
        echo "$((count++)) working on uci2010 project: $project"
        jq '. + {"crawled_date": "2015-05-01T00:00:00Z"}' $index > $new
        mv $new $index
       
      elif [ "$repo" == "uci2011" ]; then
        echo "$((count++)) working on uci2011 project: $project"
        jq '. + {"crawled_date": "2015-04-01T00:00:00Z"}' $index > $new
        mv $new $index

      elif [ "$repo" == "uciMaven" ]; then
        echo "$((count++)) working on uciMaven project: $project"
        jq '. + {"crawled_date": "2015-06-01T00:00:00Z"}' $index > $new
        mv $new $index
      elif [ "$repo" == "sourceforge" ]; then
        echo "$((count++)) working on sourceforge project: $project"
        jq '. + {"crawled_date": "2016-02-21T00:00:00Z"}' $index > $new
        mv $new $index
      fi

       #jq '. + {"crawled_date": "2015-04-01"}' $index > $new
       #     mv $new $index
    fi


done  

