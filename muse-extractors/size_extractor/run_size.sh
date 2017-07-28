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

file=totalSize.json
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
   echo "  working Size Extractor on $((count++)) Project: " $project 

   # only calculate size if index.json is present for project
   if [[ -f $project/index.json ]]
   then
     repo=$( cat $project/index.json | jq -r .repo )
     uid=$( cat $project/index.json | jq -r .uuid )
     site=$( cat $project/index.json | jq -r .site )
     meta=$( cat $project/index.json | jq  .crawler_metadata )
     output=$project/$repo/$file

     # skip project if output already exists and overwrite flag not set
     if [ "$overwrite" == "false" ]; then
       if [ -f $output ]; then
         echo "  $file exists; skipping.  (use -o flag to overwrite)"
         continue
       fi
     fi
#     echo $project >> newSFs.log     

     # Ensure repo folder exists
     if [ -d $project/$repo ]; then 

       #check crawler_metadata for size json 
       if [[ -n "$meta" ]]
       then
         exists=false 
         case "${meta[@]}" in  *"$repo/$file"*) exists=true ;; esac
   
         # if path for json doesnt exist insert it into craweler metadata
         if (! $exists)
         then
           jq '.crawler_metadata |= .+ ["./'$repo'/'$file'"]' $project/index.json > $project/tmp.index.json
           mv $project/tmp.index.json $project/index.json 
       fi
       else
         echo "  crawler_metadata undefined: " $meta
       fi

       #calculate size
       msize=0
       dsize=0
       echo "  Determining size of project..."
       size=$(du -bs --exclude=content.zip $project/ | cut -f 1 -s)
       if [ -d $project/$repo ]
       then
          msize=$(du -bs $project/$repo/ | cut -f 1 -s)
       fi
       if [ -d $project/doxygen/ ]
       then
          dsize=$(du -bs $project/doxygen/ | cut -f 1 -s)
       fi
       total_msize=$(($msize + $dsize))
       psize=$(($size-$total_msize))
       echo "{\"timestamp\":$time, \"total_size\":$size, \"metadata_size\":$total_msize, \"project_size\":$psize}" >  $project/$repo/$file
       echo "  total size: " $size
       echo "  metadata size: " $total_msize
       echo "  project size: " $psize

       # tells redis this project's metadata has been updated
       echo "  added to redis"
       redis-cli -n 0 SADD "set:metadata-updated" "$uid"

     fi  # if repo field defined
   else
      echo "  Not found: $project/index.json"
   fi
   echo ""
done
