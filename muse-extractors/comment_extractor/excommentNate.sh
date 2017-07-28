#!/bin/sh
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

## Version of the crawler. Eventually we should recreate comments.json if
## its version number is smaller.
version=1
path=/home/muse/extractors/comment_extractor
file='comments.json'

ddate_0=$( cat index.json | jq ."[\"crawled_date\"]" | sed s/\"//g )
site=$( cat index.json | jq -r .repo )
code=$( cat index.json | jq -r .code )

## Canonicalize the date format into a form that will let us do a
## string compare on two dates and let us see which is more recent.

ddate=$(date --date="$ddate_0" +%FT%H:%M:%S)


if [ ! -d $site ];
then
    mkdir $site
fi


## Add path to comments.json to the index.json under crawler_metadata
meta=$( cat index.json | jq .crawler_metadata )
#echo $meta
if [ -n "$meta" ];
then
      exists=false
      case "${meta[@]}" in  *"$file"*) exists=true ;; esac

      # if path for json doesnt exist insert it
      if [ "$exists" = "true" ]
      then
         jq '.crawler_metadata |= .+ ["./'$site'/'$file'"]' index.json > tmp.index.json
         mv tmp.index.json index.json
      fi
fi

## Here we should check if comments.json already exists, and if it does
## we should check if its version is less than $version or its date is
## less than $ddate_0. If neither one is the case we don't need to regenerate
## it.


## below there's a kludge to wrap the output of CommentExtractor in 
## another json object that also contains the version number and 
## timestamp.

if [ -d $site ];
then
#   if [ -d ./uci2011 ]; then site="uci2011"; fi
#   if [ -d ./uciMaven ]; then site="uciMaven"; fi
	{
	    echo "{"
	    echo "\t \"version\": " $version ","
	    echo "\t \"timestamp\": \"$ddate\","
	    echo "\t \"comment_data\" :"
	    find $code -type f | $path/filetypefilter $path/comment_extensions | $path/CommentExtractor
	    echo "}"
	} | jq . > $site/$file
      pwd index.json 
fi




