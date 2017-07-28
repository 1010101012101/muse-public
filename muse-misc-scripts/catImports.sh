#! /bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# This will compute the size of each project by (project, metadata, total) 
# and place the resulting json file in the corresponding repo location with 
# the other metadata.  It will update the index.json's crawler_metadata tag to
# include the location of this file as well.  If the totalSize.json file already
# exists the project will be skipped.

file=allImports07missing22.txt
count=1
overwrite=false  # will skip if already exists
one="false"

# get cmd line args
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -san)
    san="true"
    shift
    ;;
    -one)  # just analyze one project
    one="true" 
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
    echo "$0: A path to the corpus you wish to run extractor on is required."
    exit 4
fi
path=$1
echo "Running size extractor over: $path"

# Define a timestamp function
timestamp() {
  date +"%s"
}

time=$(timestamp)
total=0

# check if only want to analyze one
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
  # echo "  working combine Extractor on $((count++)) Project: " $project 



   # only calculate size if index.json is present for project
   if [[ -f $project/index.json ]]
   then
     repo=$( cat $project/index.json | jq -r .repo )
     uid=$( cat $project/index.json | jq -r .uuid )
     site=$( cat $project/index.json | jq -r .site )
     meta=$( cat $project/index.json | jq  .crawler_metadata )
     output=$file
     input=$project/imports.txt
     topics=$project/$repo/topics.json

     # skip project if topics lready exists and overwrite flag not set
     if [ "$overwrite" == "false" ]; then
       if [ -f $topics ]; then
         topicContent=$(jq . $topics)
         if [ "$topicContent" != "{}" ]; then
           #echo "  $topics exists; skipping.  (use -o flag to overwrite)"
           continue
         else
           echo " Found empty topics, rerun"    
         fi
       fi
     fi


   echo "  working combine Extractor on $((count++)) Project: " $project 
     # Ensure repo folder exists


       if [ -f $input ]; then
          cat $input >> $output
       fi



   else
      echo "  Not found: $project/index.json"
   fi
   echo ""
done
