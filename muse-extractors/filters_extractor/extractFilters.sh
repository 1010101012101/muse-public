#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Extract project level search criteria for each project and determine versions 
# 
# Checks for bytecode: (checks for .class files) or buildArchive or uciMaven project flag
# Check for object files: (checks for .o files)
# Check for source files: (checks for multiple file extensions)
# Check for android:  (checks for android manifest)
# Check for gradlew files
# Check for buildStatus

san="false"
overwrite="false"
one="false"


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
    echo "$0: A path to the corpus you wish to run extractor on is required."
    exit 4
fi
path=$1
echo "Running filter extractor over: $path"


# temp folder to extract archives into if using SAN
if [ $one == "false" ]; then
  tmp="/home/muse/extractors/filters_extractor/tmp"
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

count=1
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
android=false

# can be one of 3 types (none, single, multi)
none='none'
single='single_version'
multi='multi_version'


if [ $one == "true" ]; then
   src="echo $path"
else
   src="find $path -mindepth 9 -maxdepth 9 -type d"
fi
#Loop through all projects
#find $path -mindepth 9 -maxdepth 9 -type d  |
$src |
while read project
do
   echo "  working on $((count++)) project: $project"
   
   uuid_path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
   output=$project/filter.json

   # skip project if output already exists and overwrite flag not set
   if [ "$overwrite" == "false" ]; then
     if [ -f $output ]; then
       hasQuality=$( jq -r 'has("quality_leidos")' $output)
       if [ "$hasQuality" = true ]; then
         echo "  filter.json exists; skipping.  (use -o flag to overwrite)"
         continue
       fi
     fi
   fi

   if [ -f $project/index.json ]
   then
     site=$( cat $project/index.json | jq -r .site )
     repo=$( cat $project/index.json | jq -r .repo )
     code=$( jq -r .code $project/index.json )
     uid=$( cat $project/index.json | jq -r .uuid )
     cfiles=0  # class files count
     ofiles=0  # object files count
     sfiles=0  # src files count
     afiles=0  # android manifest files count
     gwfiles=0  # android gradle wrapper files count
     gbfiles=0  # android gradle build files count
     bytecode=$none
     objectfiles=$none
     srccode=$none
     android=false
     gradlew=false
     gradleb=false
     buildlog=false
     hasLLVM=false
     buildable=$build_no
     buildScript=false
     sizeScore=0.0 # size of src code
     starScore=0.0  # number of stars from github
     commitScore=0.0 # num of commits 
     buildScore=0.0 # build score
     archive=$uid"_code.tgz"

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

     # check to ensure src code location was specified in index.json
     bcode=$( jq -r 'has("code")' $project/index.json)
     if [ "$bcode" = true ]; then
       src_path=$project/$code

       # check to see if we need to extract a tar if on SAN
       if [ $san == "true" ]; then
          if [[ ! -d $tmp$code ]] || [[ $one == "false" ]];then
             echo "   tar xzf $project/$archive -C $tmp"
             tar xzf $project/$archive -C $tmp
          fi
          src_path=$tmp/$code
       fi

       if [ -d $src_path ]
       then
          # Check for Bytecode, java only
          # check for .class files
          cfiles=$(find $src_path -type f -iname *.class | wc -l)
          echo "   class files: $cfiles"

          # Check for Object files
          ofiles=$(find $src_path -type f -iname *.o | wc -l)
          echo "   obj files: $ofiles"

          # Check for Source files     
          #  *.c *.cc *.cxx *.cpp *.c++ *.h *.hh *.hxx *.hpp *.h *.java
          sfiles=$(find $src_path -type f \( -name *.java -o -name *.cpp -o -name *.c -o -name *.cc -o -name *.cxx -o -name *.c++ -o -name *.hpp -o -name *.h -o -name *.hh -o -name *.hxx \) | wc -l)
          echo "   src files: $sfiles"

          # Check for android manifest 
          afiles=$(find $src_path -type f -iname AndroidManifest.xml | wc -l)
          echo "   android files: $afiles"

          # Check for gradlew wrapperss 
          gwfiles=$(find $src_path -type f -iname gradlew | wc -l)
          echo "   gradlew files: $gwfiles"

          # Check for gradleb wrapperss 
          gbfiles=$(find $src_path -type f -iname build.gradle | wc -l)
          echo "   build.gradle files: $gbfiles"
       else
          echo "   src code path does not exist..."
       fi
    else
       echo "   \"code\" field was not defined in the index.json"
    fi

    #Determine if there are none,single,multi versions for each type

    # if Anroid App found
    if [ $afiles -gt 0 ]
    then
#	echo "Android App found."
        android=true
    fi
    
    # if gradlew found
    if [ $gwfiles -gt 0 ]
    then
        gradlew=true
    fi

    # if gradlew found
    if [ $gbfiles -gt 0 ]
    then
        gradleb=true
    fi

    echo "   $site"
    # special handling of UCI Maven projects
    if [ -d $project/uciMaven ]
    then
       echo "   Maven project"
       hasBcode=$( cat $project/index.json | jq .bytecode_available | sed s/\"//g )
       versions=$( cat $project/index.json | jq .version_history | sed s/\"//g  | wc -l)
       versions=$(($versions - 2)) 
       if [ "$versions" -eq 1 ]
       then 
          if [ $cfiles -gt 0 ] || [ "$hasBcode" = true ]
          then
	     bytecode=$single
          fi
          if [ $ofiles -gt 0 ]
          then
	     objectfiles=$single
          fi
          if [ $sfiles -gt 0 ]
          then
	     srccode=$single
          fi
       fi

       if [ "$versions" -gt 1 ]
       then 
          if [ $cfiles -gt 0 ] || [ "$hasBcode" = true ]
          then
	     bytecode=$multi
          fi
          if [ $ofiles -gt 0 ]
          then
	     objectfiles=$multi
          fi
          if [ $sfiles -gt 0 ]
          then
	     srccode=$multi
         fi
       fi
     
    #  If github project assume  has bare_repo, assume multi-versions of all
    elif [ -d $project/github ]
    then
        if [ $cfiles -gt 0 ]
        then
	   bytecode=$multi
        fi
        if [ $ofiles -gt 0 ]
        then
	   objectfiles=$multi
        fi
        if [ $sfiles -gt 0 ]
        then
	   srccode=$multi
        fi
    # all other repos, no way to tell of multi versions so assume single ver
    else
        #echo "   --not github or uciMaven project..."
        if [ $cfiles -gt 0 ]
        then
	   bytecode=$single
        fi
        if [ $ofiles -gt 0 ]
        then
	   objectfiles=$single
        fi
        if [ $sfiles -gt 0 ]
        then
	   srccode=$single
        fi
    fi

    # check shantanu's build paths for success and object files
    # if build success; mark has object files but no build script
    if [ -f $nfsbuild/$uuid_path/build.json ]; then
       bstatus=$(jq -r .buildStatus $nfsbuild/$uuid_path/build.json)
       echo "   C/C++ build result:  $bstatus"
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
       echo "   C/C++ build result2:  $bstatus"
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
       echo "   C/C++ build result3:  $bstatus"
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
    if [ -f $uci_home/$uuid_path/build-result.json ];then
       bstatus=$(jq -r .success $uci_home/$uuid_path/build-result.json)
       createBuild=$(jq -r .create_build $uci_home/$uuid_path/build-result.json)
       echo "   Java build result:  $bstatus"
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
       echo "   BBot C/C++ build result:  $bstatus"
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

    echo "   buildStatus: $buildable"

    if [ "$buildable" == "$build_success" ]; then
       buildScore=100
    elif [ "$buildable" == "$build_partial" ]; then
       buildScore=50
    fi

    # Calculate Quality Score
    quality=$(echo $sizeScore*.2+$commitScore*.4+$starScore*.1+$buildScore*.3 | bc ) 
    echo "   quality score: $quality"

    #Construct New Json
    echo "{\"quality_leidos\": $quality,\"buildStatus\": \"$buildable\",\"hasBuildScript\": \"$buildScript\",\"hasBytecode\": \"$bytecode\", \"hasObjectFiles\": \"$objectfiles\", \"hasSource\": \"$srccode\", \"hasBuildLog\": $buildlog, \"isAndroidApp\": $android, \"hasGradleW\": $gradlew, \"hasGradleBuild\": $gradleb, \"hasLLVM\": $hasLLVM }" > $output 


    # tells redis this project's metadata has been updated
    redis-cli -n 0 SADD "set:metadata-updated" "$uid"

    # check to see if we need to cleanup tmp folder if using SAN
    if [ $san == "true" ] && [ $one == "false" ]; then
       rm -fr $tmp/*
    fi
  fi
  echo ""
done
