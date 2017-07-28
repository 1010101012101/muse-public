#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##


version=1
path=/home/muse/extractors/comment_extractor

ddate_0=$( cat index.json | jq ."[\"download-date\"]" | sed s/\"//g )


# The code below manually checks for two special cases that are needed because 
# the index.json files are broken. Evetually this should just become 
# site=$( cat index.json | jq .site | sed s/\"//g )


if [ -d ./uci2011 ] ; then 
    site="uci2011"
else 
    if [ -d ./uciMaven ] ; then 
	site="uciMaven" ; 
    else
	site=$( cat index.json | jq .site | sed s/\"//g )
    fi
fi

#
# Find out where the code is,
#

code=$( cat index.json | jq .code | sed s/\"//g )


## If there's no download-date, use crawled_date instead

if [ "$ddate_0" = "null" ];
then
    ddate_0=$( cat index.json | jq ."[\"crawled_date\"]" | sed s/\"//g )
fi

## Canonicalize the date format into a form that will let us do a
## string compare on two dates and let us see which is more recent.

ddate=$(date --date="$ddate_0" +%FT%H:%M:%S)


if [ ! -d $site ];
then
    mkdir $site
fi

if [ -d $site ];
then

    process_directory=true

    #
    #  Check for an existing bytecode_syntax file. If one is found, only overwrite 
    # it if the download is more recent than the existing data.
    #

    if [ -f $site/bytecode_syntax.json ];
    then
	old_date=$( cat index.json | jq ."[\"timestamp\"]" | sed s/\"//g )
       
	if [ ! "$ddate" \> "$old_date" ]; 
	then 
	    process_directory=false 
	fi
    fi
	    
    if [ $process_directory = "true" ] ; 
    then

	#
	# Process all the .class files. We'll create this index
	# only for projects that actually have them.
	#

	files=$(find $code -name \*.class)
	if [ "$files" ];
	then
	    
	    #
	    #  Not all files with a .class extension are necessarily
	    # Java class files. We search through what we got and
	    # collect the Java files in an array.
	    #
	    
	    declare -a jfiles=()
	    while read -r line
	    do
		filetype=$(file -b $line)
		if (echo "$filetype" | grep -i "java" > /dev/null); then
		    jfiles+=( $line )
		fi
	    done <<< "$files"
	    
	    
	    #
	    #  Finally, process whatever Java class files we wound up
	    # with.
	    #
	    
	    if [ ${#jfiles[@]} > 0 ];
	    then
		{
		    echo "{"
		    echo "\"version\": \"$version\","
		    echo "\"timestamp\": \"$ddate\","
		    echo "\"bytecode_syntax\" :"
		    
		    first=true;
		    
		    echo "["
		    
		    for line in "${jfiles[@]}"
		    do
			if [ $first = "true" ] ; then
			    first=false
			else
			    echo ","
			fi
			
			javap -s -p "$line" | disas_parser -p
		    done <<< "$files"
		    
		    
		    echo "]}"
		} | jq . > $site/bytecode_syntax.json
	    fi
	fi
    fi
fi
