#! /bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

timeout=2700   # time to run process before bailing
file=sloc.json
xfile=sloc.xml
count=1
overwrite=false  # will skip if already exists
san=false;
one=false;

# get cmd line args
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -san)
    san="true"
    shift
    ;;
    -one)
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
echo "Running SLOC extractor over: $path"


# temp folder to extract archives into if using SAN
if [ $one == "false" ]; then
  tmp="/home/muse/extractors/sloc_extractor/tmp/"
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


# Define a timestamp function
timestamp() {
  date +"%s"
}

time=$(timestamp)
total=0

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
   echo "  working SLOC on $((count++)) Project: " $project 

   # only calculate size if index.json is present for project
   if [[ -f $project/index.json ]]
   then
     repo=$( cat $project/index.json | jq -r .repo )
     site=$( cat $project/index.json | jq -r .site )
     meta=$( cat $project/index.json | jq  .crawler_metadata )
     output=$project/$repo/$file

     code=$( cat $project/index.json | jq -r .code )
     uid=$( cat $project/index.json | jq -r .uuid )
     archive=$uid"_code.tgz"
     src_path=$project/$code

     # skip project if output already exists and overwrite flag not set
     if [ "$overwrite" == "false" ]; then
       if [ -f $output ]; then
         echo "  $file exists; skipping.  (use -o flag to overwrite)"
         continue
       fi
     fi

     # check to see if we need to extract a tar if on SAN
     if [ $san == "true" ]; then
        if [[ ! -d $tmp$code ]] || [[ $one == "false" ]];then
           if [ -f $project/$archive ]; then
             echo "   tar xzf $project/$archive -C $tmp"
             tar xzf $project/$archive -C $tmp
           else
             echo "no src_code archive found.  skipping"
             continue
           fi
        fi
        src_path=$tmp/$code
     fi

     if [ -d $src_path ]
     then

       # Create crawler_metadata sloc.json if not present
       if [ -d $project/$repo ]; then 
         #check crawler_metadata for sloc.json 
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
       fi

       #calculate sloc
       echo "  cloc --quiet --xml $src_path > $project/$repo/$xfile"
       cloc --quiet --xml $src_path | sed -n -E -e '/<?xml/,$ p'  > $project/$repo/$xfile

       echo "  converting xml results to JSON..."
       #echo "  timeout $timeout xml2json -t xml2json -o $output $project/$repo/$xfile --strip_text"
       timeout $timeout xml2json -t xml2json -o $output $project/$repo/$xfile --strip_text

       rm -fr $project/$repo/$xfile

       # tells redis this project's metadata has been updated
       redis-cli -n 0 SADD "set:metadata-updated" "$uid"


     fi  # if code not present

     # check to see if we need to cleanup tmp folder if using SAN
     if [ $san == "true" ] && [ $one == "false" ]; then
        rm -fr $tmp/*
     fi

   else
      echo "Not found: $project/index.json"
   fi
   echo ""
done
