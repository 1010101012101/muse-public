#!/bin/sh
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

site = $(cat index.json | jq .site | sed sed s/\"//g)
execute = $false
now = ($date +%y%m%d%s)

if [ -d $site ];
then
    if [ -d $site/comments.json];
    then
	version = $(cat $site/comments.json | jq .version | sed sed s/\"//g)

	if [ $version == "" ];
	then
	    execute = $true
	else
	    timestamp = $(cat $site/comments.json | jq .timestamp | sed sed s/\"//g)

	    if [ $timestamp == "" ];
	    then 
		execute = $true;
	    else
		if [ $version < VERSION || $timestamp < $now ];
		    execute = $true
		fi
	    fi
	fi

	
    find latest -type f | filetypefilter ~cc/comment_extractor/comment_extensions | CommentExtractor | jq . > $site/comments.json
fi
