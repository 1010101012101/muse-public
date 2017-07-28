#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

count=0
pcount=0
javacount=0
ccount=0
cppcount=0
jscount=0
pythoncount=0
cscount=0
rubycount=0
phpcount=0
nocount=0
emptycount=0

san="false"  # extract on SAN; requires untarring
overwrite="false" # overwrite json file if already exists
one="false"  # only run on a single program

while [[ $# > 1 ]]
do
key="$1"

# get cmd line args
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
    echo "$0: A path to the projects you wish to extract languages from  is required."
    exit 4
fi
src_path=$1

# temp folder to extract archives into if using SAN
if [ $one == "false" ]; then
  if [[ $src_path == *"0to7"* ]]; then
    tmp="/home/muse/extractors/languages/tmp07/"
  else
    tmp="/home/muse/extractors/languages/tmp08/"
  fi  
else
  if [[ $src_path == *"0to7"* ]]; then
    tmp="/home/muse/extractors/tmp07/"
  else 
    tmp="/home/muse/extractors/tmp8f/"
  fi
fi
mkdir -p $tmp
echo "Using tmp folder: $tmp"

sdate=$(date +'%m_%d_%y')
spath=$(echo $src_path | rev | cut -d "/" -f 1 | rev)

echo "starting language extractor..."

if [ $one == "false" ]; then
   src=$(find $src_path -maxdepth 9 -mindepth 9 -type d)
else
   src=$src_path
fi
#for foldername in $(find $src_path -maxdepth 9 -mindepth 9 -type d)
for foldername in $src
do

   echo "  working on $((++count)) project:  $foldername" 

   if [ -f $foldername/index.json ]; then

      repo=$(jq -r .repo $foldername/index.json)
      uid=$( cat $foldername/index.json | jq -r .uuid )
      code=$(jq -r .code $foldername/index.json)
      archive=$uid"_code.tgz"

      output=$foldername/$repo/languages.json

      # skip project if output already exists and overwrite flag not set
      if [ "$overwrite" == "false" ]; then
        
        if [ -f $output ]; then
           empty=$(jq . $output)
           if [ "$empty" != "{}" ]; then
              if [[ "$empty" == *"\"Java\": 0"* ]]; then
                ((emptycount++))
                echo "  ZERO \"Java\": 0; re-running extractor"
              elif [[ "$empty" == *"\"Javascript\""* ]]; then
                echo "  WRONG Javascript; re-running extractor" 
                ((emptycount++))
              else
                echo "  languages.json exists and non empty; skipping.  (use -o flag to overwrite)"
                echo ""
                continue
              fi
           else
              ((emptycount++))
              echo "  found empty languages.json; re-running extractor"
           fi
        fi
      fi
      
      if [ "$repo" != "null" ]; then
         if  [ "$code" != "null" ]; then
            src_path=$foldername/$code

            # check to see if we need to extract a tar if on SAN
            if [ $san == "true" ]; then
               if [[ ! -d $tmp$code ]] || [[ $one == "false" ]];then
                 echo "  tar xzf $foldername/$archive -C $tmp"
                 tar xzf $foldername/$archive -C $tmp
               fi
               src_path=$tmp/$code
            fi


            # Languages.json
            ljson=$foldername/$repo/languages.json
            ltemp=$foldername/$repo/tmp.languages.json
            foundC=false
            foundCpp=false
            foundJava=false
            foundPython=false
            foundJavascript=false
            foundPHP=false
            foundCS=false
            foundRuby=false

            echo "{}" > $ljson
            csize=$(find $src_path -type f -iname '*.c' -print0 | xargs -r0 du -ba | awk '{sum+=$1} END {print sum}')
#            csize=$(ls -lR --file-type $foldername/$code/ | grep '.c$' | awk '{total += $5} END {print total}')
            if [[ ! -z "$csize" ]] && [[ "$csize" -gt 0 ]]; then
               echo "   C code found: $csize"
               foundC=true
               ((ccount++))
               jq '. + {"C": '$csize'}' $ljson > $ltemp
               mv $ltemp $ljson
            fi
            cppsize=$(find $src_path -type f -iname '*.cpp' -print0 | xargs -r0 du -ba | awk '{sum+=$1} END {print sum}')
#            cppsize=$(ls -lR --file-type $proj/$code/ | grep '.cpp$\|.cxx$\|.hpp$' | awk '{total += $5} END {print total}')
            if [[ ! -z "$cppsize" ]] && [[ "$cppsize" -gt 0 ]]; then
               echo "   C++ code found: $cppsize"
               foundCpp=true
               ((cppcount++))
               jq '. + {"C++": '$cppsize'}' $ljson > $ltemp
               mv $ltemp $ljson
            fi
            jsize=$(find $src_path -type f -iname '*.java' -print0 | xargs -r0 du -ba | awk '{sum+=$1} END {print sum}')
            if [[ ! -z "$jsize" ]] && [[ "$jsize" -gt 0 ]]; then
               echo "   Java code found: $jsize"
               foundJava=true
               ((javacount++))
               jq '. + {"Java": '$jsize'}' $ljson > $ltemp
               mv $ltemp $ljson
            fi
            jssize=$(find $src_path -type f -iname '*.js' -print0 | xargs -r0 du -ba | awk '{sum+=$1} END {print sum}')
            if [[ ! -z "$jssize" ]] && [[ "$jssize" -gt 0 ]]; then
               echo "   Javascript code found: $jssize"
               foundJavascript=true
               ((jscount++))
               jq '. + {"JavaScript": '$jssize'}' $ljson > $ltemp
               mv $ltemp $ljson
            fi
            pysize=$(find $src_path -type f -iname '*.py' -print0 | xargs -r0 du -ba | awk '{sum+=$1} END {print sum}')
            if [[ ! -z "$pysize" ]] && [[ "$pysize" -gt 0 ]]; then
               echo "   Python code found: $pysize"
               foundPython=true
               ((pythoncount++))
               jq '. + {"Python": '$pysize'}' $ljson > $ltemp
               mv $ltemp $ljson
            fi
            cssize=$(find $src_path -type f -iname '*.cs' -print0 | xargs -r0 du -ba | awk '{sum+=$1} END {print sum}')
            if [[ ! -z "$cssize" ]] && [[ "$cssize" -gt 0 ]]; then
               echo "   C# code found: $cssize"
               foundCS=true
               ((cscount++))
               jq '. + {"C#": '$cssize'}' $ljson > $ltemp
               mv $ltemp $ljson
            fi
            phpsize=$(find $src_path -type f -iname '*.php' -print0 | xargs -r0 du -ba | awk '{sum+=$1} END {print sum}')
            if [[ ! -z "$phpsize" ]] && [[ "$phpsize" -gt 0 ]]; then
               echo "   PHP code found: $phpsize"
               foundPHP=true
               ((phpcount++))
               jq '. + {"PHP": '$phpsize'}' $ljson > $ltemp
               mv $ltemp $ljson
            fi
            rubysize=$(find $src_path -type f -iname '*.rb' -print0 | xargs -r0 du -ba | awk '{sum+=$1} END {print sum}')
            if [[ ! -z "$rubysize" ]] && [[ "$rubysize" -gt 0 ]]; then
               echo "   Ruby code found: $rubysize"
               foundRuby=true
               ((rubycount++))
               jq '. + {"Ruby": '$rubysize'}' $ljson > $ltemp
               mv $ltemp $ljson
            fi

            if [ "$foundJava" = "false" ] && [ "$foundCpp" = "false" ] && [ "$foundC" = "false" ] && [ "$foundJavascript" = "false" ] && [ "$foundPython" = "false" ] && [ "$foundCS" = "false" ] && [ "$foundPHP" = "false" ] && [ "$foundRuby" = "false" ]; then
	      echo "   No source found for"  
              ((nocount++))
   #           echo $foldername >> $log
              #rm -fr $ljson
    #        else
    #         echo $foldername >> $dlog
            else
               # src code found and computed
               # add uid to updated list on redis
               redis-cli -n 0 SADD "set:metadata-updated" "$uid"
            fi

            # clear tmp directory after each project; when doing SAN projects
            if [ $san == "true" ] && [ $one == "false" ]; then
               rm -fr $tmp/*
            fi
        fi    
       fi
   fi 
   echo ""
done


if [ $one == "false" ]; then
echo "Projects with Java: $javacount"
echo "Projects with c: $ccount"
echo "Projects with c++ $cppcount"
echo "Projects with c# $cscount"
echo "Projects with python $pythoncount"
echo "Projects with js $jscount"
echo "Projects with php $phpcount"
echo "Projects with ruby $rubycount"
echo "Projects with No SRC: $nocount"
echo "Projects with empty languages, that were fixed: $emptycount"

#echo "" >> $dlog
#echo "Projects with Java: $javacount" >> $dlog
#echo "Projects with c: $ccount" >> $dlog
#echo "Projects with c++ $cppcount" >> $dlog
#echo "Projects with c# $cscount" >> $dlog
#echo "Projects with python $pythoncount" >> $dlog
#echo "Projects with js $jscount" >> $dlog
#echo "Projects with php $phpcount" >> $dlog
#echo "Projects with ruby $rubycount" >> $dlog
#echo "Projects with No SRC: $nocount" >> $dlog
#echo "Projects with empty languages, that were fixed: $emptycount" >> $dlog
fi
