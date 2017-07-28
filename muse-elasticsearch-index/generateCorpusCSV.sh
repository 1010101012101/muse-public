#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Create a CSV file of projects to pass to our ElasticSearch indexer 

#if [[ $# != 1 ]]; then
#    echo "$0: A path to the corpus you wish to run extractor on is required."
#    exit 4
#fi

src=/data/corpus_8tof/
src2=/data/corpus_0to7/
dest=$1

sdate=$(date +'%m_%d_%y')
log=$sdate"_CorpusProjects.csv"
echo "Creating: $log"

#Loop through all projects in corpus
find $src -mindepth 9 -maxdepth 9 -type d  |
while read project
do
    if [ -f $project/index.json ]; then
         toks=$(echo "$project" | grep -o "/" | wc -w)
         out=$(echo "$project" | sed 's/\//,/'$toks'')
         echo $out
         echo $out >> $log
    fi
done

find $src2 -mindepth 9 -maxdepth 9 -type d  |
while read project
do
    if [ -f $project/index.json ]; then
         toks=$(echo "$project" | grep -o "/" | wc -w)
         out=$(echo "$project" | sed 's/\//,/'$toks'')
         echo $out
         echo $out >> $log
    fi
done

