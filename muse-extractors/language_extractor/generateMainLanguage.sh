#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
#  Determine the main language of the project by comparing bytes of code per language
#  add paramater to info.json
count=0

san="false"
overwrite="false"

while [[ $# > 1 ]]
do
key="$1"

# get cmd line args
case $key in
    -san)
    san="true"
    shift
    ;;
    -o)
    overwrite="true"
    shift
    ;;
    *)
            # unknown option
    ;;
esac
done

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to extract languages from  is required."
    exit 4
fi

src_path=$1

main=""

sdate=$(date +'%m_%d_%y')

echo " starting language extractor..."

#for foldername in $(find $src_path -maxdepth 9 -mindepth 9 -type d)
#do

find $src_path -maxdepth 9 -mindepth 9 -type d |
while read foldername
do
   #echo "working on $((++count)) project:  $foldername" 
   echo "working on $((++count)) project:  $foldername" 

   if [ -f $foldername/index.json ]; then

      repo=$(jq -r .repo $foldername/index.json)
      languages=$foldername/$repo/languages.json

      if [ -f $languages ]; then

         java=$(jq -r .Java $languages)
         cpp=$(jq -r '.["C++"]' $languages)
         cc=$(jq -r .C $languages)
         if [[ ! -z "$java" ]] && [[ "$java" -gt 0 ]]; then
             echo "  Java: " $java
         else
             java=0
         fi
         if [[ ! -z "$cpp" ]] && [[ "$cpp" -gt 0 ]]; then
             echo "  C++: " $cpp
         else
             cpp=0
         fi
         if [[ ! -z "$cc" ]] && [[ "$cc" -gt 0 ]]; then
             echo "  C: " $cc
         else
             cc=0
         fi
      fi

      if [[ "$java" -gt 0 ]] && [[ "$java" -gt "$cpp" ]] && [[ "$java" -gt "$cc" ]]; then
          main="Java"
      elif [[ "$cpp" -gt 0 ]] && [[ "$cpp" -gt "$java" ]] && [[ "$cpp" -gt "$cc" ]]; then
          main="C++"
      
      elif [[ "$cc" -gt 0 ]] && [[ "$cc" -gt "$cpp" ]] && [[ "$cc" -gt "$java" ]]; then
          main="C"
      else
          main=""
      fi

      echo "  Main language:  $main"


      #  Add main language to info.json
      if [ -f $foldername/$repo/info.json ]; then
         jq '. |= .+ {"languageMain": "'$main'"}' $foldername/$repo/info.json > $foldername/$repo/info.json.tmp
         mv $foldername/$repo/info.json.tmp $foldername/$repo/info.json
      fi 

    fi  
done

