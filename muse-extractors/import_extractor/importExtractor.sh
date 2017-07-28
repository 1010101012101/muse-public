#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# extract all imports and #includes from all C/C++/Java source files 
# into a common output file called imports.txt

#AVEIFS=$IFS
#IFS=$(echo -en "\n\b")

count=1
fcount=0
san="false"
overwrite="false"
one="false"

while [[ $# > 1 ]]
do
key="$1"

# get cmd line args
case $key in
    -san)
    san="true"
    shift # past argument
    ;;
    -one)
    one="true"
    shift # past argument
    ;;
    -o)
    overwrite="true"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
done

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to extract is required."
    exit 4
fi
path=$1


# temp folder to extract archives into if using SAN
if [ $one == "false" ]; then
  tmp="/home/muse/extractors/import_extractor/tmp/"
else
  if [[ $path == *"0to7"* ]]; then
    tmp="/home/muse/extractors/tmp07/"
  elif [[ $path == *"8tof"* ]]; then
    tmp="/home/muse/extractors/tmp8f/"
  else
    tmp="/home/muse/extractors/tmp/"
  fi
fi
mkdir -p $tmp


# check if only want to analyze one project
if [ $one == "true" ]; then
   src="echo $path"
else
   #Loop through all projects
   src="find $path -mindepth 9 -maxdepth 9 -type d"
fi

#for project in $(find $path -maxdepth 9 -mindepth 9 -type d )
#find $path -mindepth 9 -maxdepth 9 -type d  |

$src |
while read project
do
  echo "  working imports on $((count++)) project: $project"

  # Read and parse index.json for paticular values
  if [ -f $project/index.json ]; then
     code=$( cat $project/index.json | jq -r .code )
     uid=$( cat $project/index.json | jq -r .uuid )
     archive=$uid"_code.tgz"
     output=$project/imports.txt
     src_path=$project/$code
     fcount=0

     # skip project if output already exists and overwrite flag not set
     if [ "$overwrite" == "false" ]; then
        if [ -f $output ]; then
           echo "  $file exists; skipping.  (use -o flag to overwrite)"
           continue
        fi
     else
        echo "" > $output  # reset file
     fi

     # check to see if we need to extract a tar if on SAN
     if [ $san == "true" ]; then
        if [[ ! -d $tmp$code ]] || [[ $one == "false" ]];then
           if [ -f $project/$archive ]; then
             echo "   tar xzf $project/$archive -C $tmp"
             tar xzf $project/$archive -C $tmp
           else
             continue
           fi
        fi
        src_path=$tmp$code
     fi


     # if project has src code
     bcode=$( jq -r 'has("code")' $project/index.json)
     if [ "$bcode" = true ]; then
         # Search all c/c++/java src code for imports/includes
         for file in $(find $src_path -type f -name '*.cpp' -o -name '*.h' -o -name '*.c' -o -name '*.java' -o -name '*.cc' -o -name '*.cxx' -o -name '*.hh' -o -name '*.hxx' -o -name '*.hpp' -o -name '*.c++' -o -name '*.h++') 
         do
            ((fcount=fcount+1))
            if [[ "$file" == *.java ]]; then
               grep -F "import " "$file" >> $output
            else
               grep -F "#include" "$file" >> $output
            fi
         done
     fi # end if code exists

     # tells redis this project's metadata has been updated
     redis-cli -n 0 SADD "set:metadata-updated" "$uid"

     # check to see if we need to cleanup tmp folder if using SAN
     if [ $san == "true" ] && [ $one == "false" ]; then
        rm -fr $tmp/*
     fi
  fi
 # else
 #   echo "  imports already exists...skipping..."
 # fi
  echo "  --$fcount-files-found-----------"
  echo ""
done
#IFS=$SAVEIFS
