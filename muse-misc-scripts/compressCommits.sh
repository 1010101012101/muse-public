#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Iterate all corpus projects; read/parse files from each project

count=1

if [[ $# != 1 ]]; then
    echo "$0: A path to the corpus you wish to run compress on is required."
    exit 4
fi

src=$1

echo "Running compress commits  over: $src"


#src="/data/corpus_0to7/hackathon2/"
compact="commits.compact.json"

#Loop through all projects
#for commits in $(find $src -maxdepth 11 -mindepth 11 -type f -name commits.json)
find $src -mindepth 11 -maxdepth 11 -type f -name commits.json  |
while read commits
do
   echo "Working on $((count++)) project: $commits"
   
  path=$(echo $commits | rev | cut -d "/" -f 2- | rev)
  #echo "Path: $path"

  # Read and parse index.json for paticular values
  echo "  jq . -c $commits > $path/$compact"
#  jq . -c $commits > $path/$compact
  jq . $commits > $path/$compact
  echo "  mv $path/$compact $commits" 
  mv $path/$compact $commits 

  echo ""

done

