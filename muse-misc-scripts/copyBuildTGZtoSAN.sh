#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# Archive all projects in a given path and 
# Copy arhives into the XTFS volume 
# src - supply src path of projects to copy

count=1
if [[ $# != 1 ]]; then
    echo "$0: A path to the projects you wish to copy to XTFS is required."
    exit 4
fi

src=$1

dest="/data/corpus-xtfsvol"

#Loop through all projects
#find $src -mindepth 10 -maxdepth 10 -type f -name "*.tgz"  |

while read project
do

  echo "Working on $((count++)) file: $project ================="
  path=$(echo $project | rev | cut -d "/" -f 1-9 | rev)
  uid=$(echo $project | rev | cut -d "/" -f 2 | rev)
  tgz=$(echo $project | rev | cut -d "/" -f 1 | rev)
  
#  echo $path
#  echo $tgz

  # skip any projects that already exist; check for empty code archives and remove
  if [ -f $dest/$path/$tgz ]; then
     echo "  already copied, skipping project..."
     continue
  fi 

  echo "  mkdir -p $dest/$path/"
  mkdir -p $dest/$path/

  # Archive the whole project 
#  cd $project

  echo "  cp -fr $project/*.tgz $dest/$path/"
  cp -fr $project/*.tgz $dest/$path/

  # Archive everything else in project except latest src, and metadata files used for indexing
#  echo "   tar -czf $dest/$path/$tgz ."
#  tar czf $dest/$path/$tgz . 

  echo ""
#done
done < /home/muse/corpusRAT.txt

