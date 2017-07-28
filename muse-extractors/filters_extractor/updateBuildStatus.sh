#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Update only build status of filter.json for each project given in txt file
# 
# Checks for bytecode
# Check for buildStatus
# Check for buildScript

if [[ $# != 1 ]]; then
    echo "$0: A file of project paths to update filter.json."
    exit 4
fi

path=$1

echo "Running update Filter extractor over: $path"

count=1
countu=1

nfsbuild='/nfsbuild'  # shantanu's original build path (nfs mounted from muse1-int:/data/build/
nfsbuild07='/data/builder_SAN/output'  # shantanu's 2nd build path (nfs mounted from muse1-int
nfsbuild8f='/data/builder_SAN/output2'  # shantanu's 3rd build path (nfs mounted from muse1-int
uci_home='/data/UCIbuilds' # uci build path (nfs mounted from muse1-int:/raid5/clopes/all_builds_take3
bbot_home='/data/buildbot' # buildbot outtput path

build_no='no_attempt'
build_fail='failure'
build_success='success'
build_partial='partial'

hasLLVM=false

# can be one of 3 types (none, single, multi)
none='none'
single='single_version'
multi='multi_version'


#Loop through all projects
find $path -mindepth 9 -maxdepth 9 -type d  |

while read project
do
#   echo "Working on $((count++)) project: $project"
   
   uuid_path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)

   output=$project/filter.json
   output_tmp=$project/filter.json.tmp

   bytecode=$none
   objectfiles=$none
   buildlog=false
   buildable=$build_no
   buildScript=false
   hasLLVM=false

   if [ -f $output ]; then

     # check shantanu's build paths for success and object files
     # if build success; mark has object files but no build script
     if [ -f $nfsbuild/$uuid_path/build.json ]; then
       bstatus=$(jq -r .buildStatus $nfsbuild/$uuid_path/build.json)
#       echo "   C/C++ build result:  $bstatus"
       if [ "$bstatus" == "success" ] ; then 
          objectfiles=$single # only built one verision of the code
          buildable=$build_success 
       elif [ "$bstatus" == "partial" ] ; then
          objectfiles=$single # only built one verision of the code
          buildable=$build_partial
       else
          buildable=$build_fail
       fi
     fi 

     # check shantanu's 2nd build paths for success and object files
     # if build success; mark has object files but no build script
     if [ -f $nfsbuild07/$uuid_path/build.json ]; then
       bstatus=$(jq -r .buildStatus $nfsbuild07/$uuid_path/build.json)
#       echo "   C/C++ build result2:  $bstatus"
       if [ "$bstatus" == "success" ] ; then
          objectfiles=$single # only built one verision of the code
          buildable=$build_success
       elif [ "$bstatus" == "partial" ] ; then
          objectfiles=$single # only built one verision of the code
          if [ "$buildable" != "$build_success" ]; then
            buildable=$build_partial
          fi
       else
          if [ "$buildable" == "$build_no" ]; then
             buildable=$build_fail
          fi

       fi
     fi

     # check shantanu's 3rd build paths for success and object files
     # if build success; mark has object files but no build script
     if [ -f $nfsbuild8f/$uuid_path/build.json ]; then
       bstatus=$(jq -r .buildStatus $nfsbuild8f/$uuid_path/build.json)
#       echo "   C/C++ build result2:  $bstatus"
       if [ "$bstatus" == "success" ] ; then
          objectfiles=$single # only built one verision of the code
          buildable=$build_success
       elif [ "$bstatus" == "partial" ] ; then
          objectfiles=$single # only built one verision of the code
          if [ "$buildable" != "$build_success" ]; then
            buildable=$build_partial
          fi
       else
          if [ "$buildable" == "$build_no" ]; then
             buildable=$build_fail
          fi
       fi
     fi

     # check uci build path for success
     # if success, mark has bytecode and has buildscript
     uid=$uuid_path
 #     if [[ ${uid:0:1} == 0 || ${uid:0:1} == 1 || ${uid:0:1} == 2 || ${uid:0:1} == 3 || ${uid:0:1} == 4 || ${uid:0:1} == 5 || ${uid:0:1} == 6 || ${uid:0:1} == 7 ]]; then
 #       build_home=$uci_home"/corpus_0to7"
 #     else
 #       build_home=$uci_home"/corpus_8tof"
 #     fi

#     echo "  UCI dir: $uci_home/$uuid_path/"
     if [ -f $uci_home/$uuid_path/build-result.json ];then
       bstatus=$(jq -r .success $uci_home/$uuid_path/build-result.json) 
       createBuild=$(jq -r .create_build $uci_home/$uuid_path/build-result.json) 
#       echo "   Java build result:  $bstatus"
       if [ "$bstatus" = true ] ; then 
          buildable=$build_success
          buildScript=true

	  if [ "$createBuild" = true ] ; then
             bytecode=$single
          fi
       else
          if [ "$buildable" == "$build_no" ]; then
             buildable=$build_fail
          fi
       fi
    fi

     # check buildbot's build output paths for success and object files
     # if build success; mark has object files but no build script
     if [ -f $bbot_home/$uuid_path/build.json ]; then
       bstatus=$(jq -r .buildStatus $bbot_home/$uuid_path/build.json)
 #      echo "  BBot C/C++ build result:  $bstatus"
       if [ "$bstatus" == "success" ] ; then
          objectfiles=$single # only built one verision of the code
          hasLLVM=true
          buildable=$build_success
       elif [ "$bstatus" == "partial" ] ; then
          objectfiles=$single # only built one verision of the code
          hasLLVM=true
          if [ "$buildable" != "$build_success" ]; then
            buildable=$build_partial
          fi
       else
          hasLLVM=false
          buildable=$build_fail
          if [ "$buildable" == "$build_no" ]; then
             buildable=$build_fail
          fi
       fi
     fi


     # Calculate new Quality score if build changed from fail to success/partial 
     if [ -f $output ]; then
       buildableOLD=$(jq -r .buildStatus $output)
     fi

     quality_old=$(jq -r .quality_leidos $output)
 #    echo "  quality old: $quality_old"
     if [ "$buildableOLD" == "$build_fail" ]; then
       if [ "$buildable" == "$build_success" ]; then
          buildScore=100
          # Calculate Quality Score
          quality=$(echo $quality_old+$buildScore*.3 | bc )
          echo "$((countu++)) success: $project  quality new: $quality old: $quality_old"
          jq '. + {"quality_leidos": '$quality'} + {"buildStatus": "'"$buildable"'"} + {"hasBuildScript": "'"$buildScript"'"} + {"hasBytecode": "'"$bytecode"'"} + {"hasLLVM": '"$hasLLVM"'}' $output > $output_tmp
          mv $output_tmp $output
       elif [ "$buildable" == "$build_partial" ]; then
          buildScore=50
          # Calculate Quality Score
          quality=$(echo $quality_old+$buildScore*.3 | bc )
          echo "$((countu++)) partial: $project  quality new: $quality old: $quality_old"
          jq '. + {"quality_leidos": '$quality'} + {"buildStatus": "'"$buildable"'"} + {"hasBuildScript": "'"$buildScript"'"} + {"hasBytecode": "'"$bytecode"'"} + {"hasLLVM": '"$hasLLVM"'}' $output > $output_tmp
          mv $output_tmp $output
       fi
     fi
  fi
done #<$path
