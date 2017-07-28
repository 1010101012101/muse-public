#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Run automated extractors over the corpus in the SAN 
# need to supply corpus path (must be on SAN) 

count=1

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects."
    exit 4
fi

src=$1

if [[ $src == *"0to7"* ]]; then
  tmp="tmp07/"
elif [[ $src == *"8tof"* ]]; then
  tmp="tmp8f/"
else
  tmp="tmp/"
fi
echo "using tmp directory: " $tmp
mkdir -p $tmp

sleep 3 

#Loop through all projects
find $src -mindepth 9 -maxdepth 9 -type d  |
while read project
do

  if [  -f $project/index.json ]; then
   echo "Working on $((count++)) project: $project ================="

   path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
   uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
   code_tgz=$uid"_code.tgz"
   meta_tgz=$uid"_metadata.tgz"
   repo=$(jq -r .repo $project/index.json)
   code=$(jq -r .code $project/index.json)

   # determine if src code present
   if [ "$code" != "null" ]; then

    # Check languages metadata; rerun if not present or empty
    langJson=$project/$repo/languages.json
    if [ ! -f $langJson ]; then
       echo "languages.json NOT present"
       ./language_extractor/generateLanguagesJson.sh -san -one $project
    else
       contents=$(jq . $langJson)
       if [ "$contents" == "{}" ]; then
          echo "  languages.json empty"
          ./language_extractor/generateLanguagesJson.sh -san -one $project
       else
         echo "languages.json found"
       fi
    fi

    echo "-------------------------"
    # Check doxygen.json
    if [ ! -f $project/doxygen/doxygen.json ]
    then
       #skip doxygen if we have previoulsy tagged it as a timeout project
       found=$(redis-cli smembers "set:doxygen-timeouts" | grep $uid)
       if [[ -z "$found" ]]; then
          #run it
          echo "  doxygen.json NOT present, re-running"
          ./doxygen_extractor/run_doxygen.sh -san -one $project
       else
          echo "  doxgen timeout found, skipping.."
       fi
    else
       echo "doxygen.json found"
    fi
    echo "-------------------------"

    # Check filter.json
    if [ ! -f $project/filter.json ]
    then
       #run it
       echo "filter.json NOT present"
       ./filters_extractor/extractFilters.sh -san -one $project
    else
       echo "filter.json found"
    fi

    echo "-------------------------"
    # Check sloc.json
    if [ ! -f $project/$repo/sloc.json ]
    then
       #run it
       echo "sloc.json NOT present"
       ./sloc_extractor/run_sloc.sh -san -one $project
    else
       echo "sloc.json found"
    fi

    echo "-------------------------"
    # Check imports.txt
    if [ ! -f $project/imports.txt ]
    then
       #run it
       echo "imports.txt NOT present"
       ./import_extractor/importExtractor.sh -san -one $project
    else
       echo "imports.txt found"
    fi

   # no src code present in project, skip
   else
     echo "No Src Code present..."
   fi

 
   echo "-------------------------"
    # Check size.json
    if [ ! -f $project/$repo/totalSize.json ]
    then
       #run it
       echo "size.json NOT present"
       ./size_extractor/run_size.sh -san -one $project
    else
       echo "size.json found"
    fi
    echo "-------------------------"
    echo ""

    rm -fr $tmp/*
  fi
done

