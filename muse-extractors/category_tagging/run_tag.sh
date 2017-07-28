#! /bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# This will compute the topics of each project by looking for certain libraries 

file="topics.json"
temp="topics.json.tmp"

count=1
tagcount=1
seccount=0
dbcouunt=0
xmlcount=0
netcount=0
iocount=0
uicount=0
imgcount=0
cmpcount=0
webcount=0
cybcount=0
testcount=0
mobilecount=0
nolang_count=0

overwrite=false  # will skip if already exists
one="false"

# get cmd line args
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -one)  # just analyze one project
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
echo "Running topic extractor over: $path"
# Define a timestamp function
timestamp() {
  date +"%s"
}

time=$(timestamp)
total=0

# check if only want to analyze one
if [ $one == "false" ]; then
   src=$(find $path -maxdepth 9 -mindepth 9 -type d)
#  src="find $path -maxdepth 9 -mindepth 9 -type d"
else
   src=$path
fi

#$src |
#while read project
for project in $src
do
   echo "  working Topic Extractor on $((count++)) Project: " $project 
   echo "  tagged projects: $((tagcount)) " 

   # only calculate if index.json is present for project
   if [[ -f $project/index.json ]]
   then
     repo=$( cat $project/index.json | jq -r .repo )
     uid=$( cat $project/index.json | jq -r .uuid )
     site=$( cat $project/index.json | jq -r .site )
     meta=$( cat $project/index.json | jq  .crawler_metadata )
     output=$project/$repo/$file
     outtemp=$project/$repo/$temp
     input=$project/imports.txt

     # skip project if output already exists and overwrite flag not set
     if [ "$overwrite" == "false" ]; then
       if [ -f $output ]; then
         echo "  $file exists; skipping.  (use -o flag to overwrite)"
         continue
       fi
     fi
#     echo $project >> newSFs.log     

     # Ensure repo folder exists
     if [ -d $project/$repo ]; then 

       #check crawler_metadata for topics json 
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

       # if project contains input file to search
       if [ -f $input ]; then
          echo "{}" > $output

          #find topics
          networking=$(cat $input | grep -e 'net/ip.h' -e 'ace/' -e 'boost/asio' -e 'Poco/Net' -e 'Ice/Ice.h' -e '<netinet/' -e 'java.net.' -e 'io.netty.' -e 'com.esotericsoftware.kryonet' -e 'netdb.h' | wc -l)
#          echo "found network: $networking "
          if [[ "$networking" > 0 ]]; then
            ((netcount++))
            jq '. + {"Networking": '$networking'}' $output > $outtemp
            mv $outtemp $output 
          fi
          ui=$(cat $input | grep -e 'X11/Intrinsic.h' -e 'X11/Xlib.h' -e 'Xm/Xm.h' -e 'fltk/' -e 'QtGui' -e 'qapplication.h' -e 'gtk/gtk.h' -e 'wx/wx.h' -e 'vtkRenderer.h' -e '<curses.h' -e 'java.awt.' -e 'java.swing.' -e 'javax.swing' -e 'org.jfree.chart.' -e 'org.eclipse.swt' | wc -l)
#          echo "found ui:  $ui"
          if [[ "$ui" > 0 ]]; then
            ((uicount++))
            jq '. + {"UserInterface": '$ui'}' $output > $outtemp
            mv $outtemp $output 
          fi
          imaging=$(cat $input | grep -e 'gl/glu.h' -e 'magick/' -e 'CImg.h' -e 'libics.h' -e 'boost/gil' -e 'jpeglib.h' -e 'devil_internal_exports.h' -e 'EasyBMP.h' -e 'opencv2/' -e 'ij.ImageJ' -e 'net.imglib2' -e 'org.imgscalr.Scalr.' -e 'org.opencv.' | wc -l)
#          echo "found imaging:  $imaging"
          if [[ "$imaging" > 0 ]]; then
            ((imgcount++))
            jq '. + {"Imaging": '$imaging'}' $output > $outtemp
            mv $outtemp $output 
          fi
          database=$(cat $input | grep -e 'postgres.h' -e 'soci.h' -e 'otlv4.h' -e 'lmdb++.h' -e '<mysql.h>' -e 'java.sql.'  -e 'org.hibernate.' -e 'javax.persistence.' -e 'org.h2.' -e 'com.mongodb.' | wc -l)
#          echo "found database:  $database"
          if [[ "$database" > 0 ]]; then
            ((dbcount++))
            jq '. + {"Database": '$database'}' $output > $outtemp
            mv $outtemp $output 
          fi
          compression=$(cat $input | grep -e 'bzlib.h' -e 'boost/iostreams/filter/gzip.hpp' -e 'boost/iostreams/filter/zlib.hpp' -e 'boost/iostreams/filter/bzip2.hpp' -e 'java.util.zip' | wc -l)
#          echo "found compression:  $compression"
          if [[ "$compression" > 0 ]]; then
            ((cmpcount++))
            jq '. + {"Compression": '$compression'}' $output > $outtemp
            mv $outtemp $output 
          fi
          fileio=$(cat $input | grep -e 'java.io.' -e 'java.nio.' -e '<iostream>' -e 'termios.h' | wc -l)
#          echo "found fileio:  $fileio"
          if [[ "$fileio" > 0 ]]; then
            ((iocount++))
            jq '. + {"Input-Output": '$fileio'}' $output > $outtemp
            mv $outtemp $output 
          fi
          xml=$(cat $input | grep -e '<xercesc/' -e '<libxml/' -e 'tinyxml2.h'  -e 'org.apache.xerces.' -e 'org.dom4j.' -e 'org.jdom' -e 'org.jibx.' -e 'org.w3c.dom' -e 'org.xml.sax.' -e 'javax.xml.' | wc -l)
#          echo "found xml parsing:  $xml"
          if [[ "$xml" > 0 ]]; then
            ((xmlcount++))
            jq '. + {"Xml": '$xml'}' $output > $outtemp
            mv $outtemp $output 
          fi
          security=$(cat $input | grep -e 'tomcrypt.h' -e 'crypyo/' -e 'crypto++/' -e '/cryptopp' -e 'java.security.' -e 'javax.crypto' -e 'org.bouncycastle.' -e 'openssl/' -e 'cryptlib.h' | wc -l)
#          echo "found security parsing:  $security"
          if [[ "$security" > 0 ]]; then
            ((seccount++))
            jq '. + {"Security": '$security'}' $output > $outtemp
            mv $outtemp $output 
          fi
          web=$(cat $input | grep -e '<cppcms/' -e '<Wt/WApplication>' -e 'javax.servlet.' -e 'javax.faces.' -e 'javax.xml.ws.' -e 'com.google.gwt.' -e 'javax.ws.rs.' -e 'org.springframework.web.' | wc -l)
#          echo "found web parsing:  $web"
          if [[ "$web" > 0 ]]; then
            ((webcount++))
            jq '. + {"Web": '$web'}' $output > $outtemp
            mv $outtemp $output 
          fi
          cyber=$(cat $input | grep -e 'arduino.h' -e 'Arduino.h' -e 'avr/io.h' -e 'org.mavlink.' -e 'gnu.io' | wc -l)
#          echo "found cyberphysical parsing:  $cyberphysical"
          if [[ "$cyber" > 0 ]]; then
            ((cybcount++))
            jq '. + {"CyberPhysical": '$cyber'}' $output > $outtemp
            mv $outtemp $output 
          fi
          mobile=$(cat $input | grep -e 'android.app.' | wc -l)
#          echo "found mobile parsing:  $mobile"
          if [[ "$mobile" > 0 ]]; then
            ((mobilecount++))
            jq '. + {"Android": '$mobile'}' $output > $outtemp
            mv $outtemp $output 
          fi
          testing=$(cat $input | grep -e 'boost/test/' -e 'unittest++/UnitTest++.h' -e '<cppunit/' -e 'gtest/gtest.h' -e 'org.junit.' -e 'java.junit.Test' -e 'org.jbehave.scenario' | wc -l)
#          echo "found cyberphysical parsing:  $cyberphysical"
          if [[ "$testing" > 0 ]]; then
            ((testcount++))
            jq '. + {"Testing": '$testing'}' $output > $outtemp
            mv $outtemp $output 
          fi

          
          if [[ "$networking" > 0 ]] || [[ "$ui" > 0 ]] || [[ "$imaging" > 0 ]] || [[ "$database" > 0 ]] || [[ "$compression" > 0 ]] || [[ "$fileio" > 0 ]] || [[ "$xml" > 0 ]] || [[ "$security" > 0 ]] || [[ "$web" > 0 ]] || [[ "$cyber" > 0 ]] || [[ "$mobile" > 0 ]] || [[ "$testing" > 0 ]]; then
            ((tagcount++))
          else
            echo "No topics: $project"
            jq '. + {"None": 1}' $output > $outtemp
            mv $outtemp $output 

            # Determine if no topics tagged b/c of language
            langs=$project/$repo/languages.json
            if [ -f $langs ]; then
              empty=$(jq . $langs)
              echo $empty
              if [[ "$empty" != *"\"C++\""* ]] && [[ "$empty" != *"\"C\""* ]] && [[ "$empty" != *"\"Java\""* ]]; then
                 echo "no right languages"
                 ((nolang_count++))
              else 
                 if [[ "$empty" == *"\"Java\": 0"* ]]; then
                   echo "empty java"
                   ((nolang_count++))
                 fi 
              fi
            fi
          fi

          # tells redis this project's metadata has been updated
          echo "  added to redis"
          redis-cli -n 0 SADD "set:metadata-updated" "$uid"
       else
         ((nolang_count++)) 
       fi
     fi  # if repo field defined
   else
      echo "  Not found: $project/index.json"
   fi
#   echo ""
done
  echo "  security size: " $seccount
  echo "  networking size: " $netcount
  echo "  db size: " $dbcount
  echo "  ui size: " $uicount
  echo "  xml size: " $xmlcount
  echo "  imaging size: " $imgcount
  echo "  io size: " $iocount
  echo "  compression size: " $cmpcount
  echo "  web size: " $webcount
  echo "  cyberPhysical size: " $cybcount
  echo "  mobile size: " $mobilecount
  echo "  testing size: " $testcount
  echo "  not right lang size: " $nolang_count
          

