##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

if [[ $# != 1 ]]; then
    echo "$0: A text file containing the list of projects you wish to remove."
    exit 4
fi

src=$1


while read project; do

  echo "Working on: " $project
  if [ -d $project ]; then

    rm -fr $project

  fi


done <$src
