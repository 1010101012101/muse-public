#! /bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

path=/data/test

find $path -mindepth 9 -maxdepth 9 -type d | 

while read project
do

echo $project
exec sh -c "(cd{}; excomment2.sh")


done
