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

nfsbuild='/nfsbuild'  # shantanu's build path (nfs mounted from muse1-int:/data/build/
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
#find $path -mindepth 9 -maxdepth 9 -type d  |

while read project
do
   echo "Working on $((count++)) project: $project"
   
   uuid_path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)

   output=$project/filter.json
   output_tmp=$project/filter.json.tmp

   if [ -f $project/index.json ]
   then
     repo=$( cat $project/index.json | jq -r .repo )
     buildable=$build_no
     sizeScore=0.0 # size of src code
     starScore=0.0  # number of stars from github
     commitScore=0.0 # num of commits
     buildScore=0.0 # build score

     if [ -f $project/$repo/totalSize.json ]; then
       srcSize=$( jq -r .project_size $project/$repo/totalSize.json )
       if [ ! -z "$srcSize" -a "$srcSize" != "null" ]; then
          if [ "$srcSize" -ge 0 -a "$srcSize" -lt 100 ]; then
             sizeScore=10
          fi
          if [ "$srcSize" -ge 100 -a "$srcSize" -lt 1000 ]; then
             sizeScore=25
          fi
          if [ "$srcSize" -ge 1000 -a "$srcSize" -lt 100000 ]; then
             sizeScore=50
          fi
          if [ "$srcSize" -ge 100000 -a "$srcSize" -lt 100000000 ]; then
             sizeScore=75
          fi
          if [ "$srcSize" -ge 100000000 ]; then
             sizeScore=100
          fi
       fi
       echo "   sizeScore: $sizeScore"
     fi

     if [ -f $project/$repo/info.json ]; then
       stars=$( jq -r .stargazers_count $project/$repo/info.json )
       if [ ! -z "$stars" -a "$stars" != "null" ]; then
          if [ "$stars" -ge 1 -a "$stars" -lt 5 ]; then
             starScore=10
          fi
          if [ "$stars" -ge 5 -a "$stars" -lt 10 ]; then
             starScore=25
          fi
          if [ "$stars" -ge 10 -a "$stars" -lt 25 ]; then
             starScore=50
          fi
          if [ "$stars" -ge 25 -a "$stars" -lt 50 ]; then
             starScore=75
          fi
          if [ "$stars" -ge 50 ]; then
             starScore=100
          fi
       fi
       echo "   starScore: $starScore"
     fi

     if [ -f $project/$repo/commits.json ]; then
       numCommits=$( jq -r '. | length' $project/$repo/commits.json | head -n 1 )
       if [ ! -z "$numCommits" -a "$numCommits" != "null" ]; then
          if [ "$numCommits" -ge 0 -a "$numCommits" -lt 10 ]; then
             commitScore=10
          fi
          if [ "$numCommits" -ge 10 -a "$numCommits" -lt 100 ]; then
             commitScore=25
          fi
          if [ "$numCommits" -ge 100 -a "$numCommits" -lt 500 ]; then
             commitScore=50
          fi
          if [ "$numCommits" -ge 500 -a "$numCommits" -lt 1000 ]; then
             commitScore=75
          fi
          if [ "$numCommits" -ge 1000 ]; then
             commitScore=100
          fi
       fi
       echo "   commitScore: $commitScore"
     fi

     if [ -f $output ]; then
       buildable=$(jq -r .buildStatus $output)
     fi

     if [ "$buildable" == "$build_success" ]; then
       buildScore=100
     elif [ "$buildable" == "$build_partial" ]; then
       buildScore=50
     fi
     
     echo ""
     quality_old=$(jq -r .quality_leidos $output)
     echo "  quality old: $quality_old"
     # Calculate Quality Score
     quality=$(echo $sizeScore*.2+$commitScore*.4+$starScore*.1+$buildScore*.3 | bc )
     echo "  quality new: $quality"


     #Update Filter.json
     jq '. + {"quality_leidos": '$quality'}' $output > $output_tmp
     mv $output_tmp $output
 
  fi
  echo ""
done <$path
