#!/bin/bash
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

version=2
path=/home/muse/extractors/comment_extractor

indexfile="index.json"

ddate_0=$( cat "$indexfile" | jq ."[\"download-date\"]" | sed s/\"//g )


site=$( cat "$indexfile" | jq .repo | sed s/\"//g )

#
# Find out where the code is,
#

code=$( cat "$indexfile" | jq .code | sed s/\"//g )

code_version=$( cat "$indexfile" | jq .version | sed s/\"//g )


## If there's no download-date, use crawled_date instead

if [ "$ddate_0" = "null" ];
then
    ddate_0=$( cat "$indexfile" | jq ."[\"crawled_date\"]" | sed s/\"//g )
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
	old_date=$( cat "$site/bytecode_syntax.json" | jq ."[\"timestamp\"]" | sed s/\"//g )
	oldversion=$( cat "$site/bytecode_syntax.json" | jq ."[\"version\"]" | sed s/\"//g )
       
	if [ ! "$ddate" \> "$old_date" ] && [ ! "$version" \> "$oldversion" ]; 
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
	jarfiles=$(find $code -name \*.jar)
	jarfiles+=$(find $code_version -name \*.jar)
	
	if [ "$files" ] || [ "$jarfiles" ];
	then
	    
	    #
	    #  This array will hold all our class files
	    #

	    declare -a jfiles=()

	    #
	    #  This holds a jar file for each class file
	    #

	    declare -a jars=()

	    #
	    #  An array of fake paths that say where things are within the 
	    # jar file.
	    #


	    if [ "$files" ];
	    then

		#
		#  Not all files with a .class extension are necessarily
		# Java class files. We search through what we got and
		# collect the Java files in an array.
		#
		
		
		while read -r line
		do
		    filetype=$(file -b $line)
		    if (echo "$filetype" | grep -i "java" > /dev/null); then
			jfiles+=( $line )
		    fi
		done <<< "$files"
		
	    fi

	    # 
	    #  Now process the jar files
	    #

	    if [ "$jarfiles" ]; 
		then

		while read -r line
		do
		    filetype=$(file -b $line)
		    if (echo "$filetype" | grep -i "zip" > /dev/null); then
			jars+=( $line )
		    fi
		done <<< "$jarfiles"
	    fi

	    #
	    #  Process whatever files we wound up with
	    #
	    
	    if [ ${#jfiles[@]} > 0 ] || [ ${#jars[@]} > 0 ];
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
		    done

                    for line in "${jars[@]}"
                    do
			jarclasses=$(jar -tf $line | grep class | sed 's/.class//g')
			if [ "$jarclasses" ];
			then
                            if [ $first = "true" ] ; then
				first=false
                            else
				echo ","
                            fi

                            javap -s -p -classpath "$line" $jarclasses | disas_parser -p -j "$line"
			fi
                    done

		    
		    
		    echo "]}"
		} | tee junk2 | jq . > $site/bytecode_syntax.json
	    fi
	fi
    fi
fi
