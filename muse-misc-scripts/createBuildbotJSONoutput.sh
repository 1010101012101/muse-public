#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# Create JSON output for buildbot archives.

count=1
counts=0
countp=0
countf=0

if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to work."
    exit 4
fi

src=$1

fail='failure'
success='success'
partial='partial'
org='/data/corpus_0to7'

#Loop through all projects
for project in $(find $src -maxdepth 9 -mindepth 9 -type d)
do

#while read project
#do

   echo "Working on $((count++)) project: $project ================="

    if [ -f $project/build.json ]; then
       echo "  skipping, build.json already present"
	((countf++))
       continue
    fi

    path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
    uid=$(echo $project | rev | cut -d "/" -f 1 | rev)
    code_tgz=$uid"_code.tgz"
    obj_org_count=0
    obj_bb_count=0
    num_src=0
    result=$fail
    bjson=$project/"build.json"

    if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
       org='/data/corpus_0to7'
    else
       org='/data/corpus_8tof'
    fi

    org_tar=$org/$path/$code_tgz
    if [ -f $org_tar ]; then

      obj_org_count=$(tar tzvf $org_tar --exclude='.git'  --exclude='.svn' | grep -c '\.o$')
      num_src=$(tar tzvf $org_tar --exclude='.git'  --exclude='.svn' | grep -Ec '\.c$|\.cpp$|\.cxx$|\.c\+\+$|\.cc$')
      echo "  $num_src number of source files"
      echo "  $obj_org_count object files found in ORIGINAL"
    fi

    bb_tar=$(ls $project/*.tgz | tail -n 1)

    if [ -f $bb_tar ]; then
	obj_bb_count=$(tar tzvf $bb_tar --exclude='.git' --exclude='.svn' --exclude='*llvm.o*' | grep -c '\.o$')
        echo "  $obj_bb_count object files found in BUILDBOT"
    fi


    # if obj files from buildbot > objs files already there from src
    if [[ "$obj_bb_count" -gt "$obj_org_count" ]]; then
	# if objs from buildbot >= num source files
        if [[ "$obj_bb_count" -ge "$num_src" ]]; then
            echo "  SUCCESS"
	    ((counts++))
            result=$success
        else
            echo "  PARTIAL"
	    ((countp++))
            result=$partial
        fi
    else
        echo "  FAIL"
	((countf++))
	result=$fail
    fi

    #Construct New Json
    echo "{\"sourcePath\": \"$org_tar\",\"projectName\": \"$uid\",\"builds\": [{ \"numSources\": \"$num_src\", \"numObjectsPreBuild\": \"$obj_org_count\", \"numObjectsGenerated\": \"$obj_bb_count\", \"buildTarPath\": \"$bb_tar\", \"numObjectsPostBuild\": \"$obj_bb_count\", \"os\": \"ubuntu14\"}], \"buildStatus\": \"$result\" }" > $bjson
 


done < $1 
#done 

echo " # success: " $counts
echo " # partial: " $countp
echo " # failure: " $countf

