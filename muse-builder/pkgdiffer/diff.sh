#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

f1=musebuilder-ubuntu14.pkg
f2=ubuntu14_pkg

tail -n +6 ${f1}_list | cut -d " " -f 3 | sort > ${f1}_names
tail -n +6 ${f2}_list | cut -d " " -f 3 | sort > ${f2}_names

#echo "head of ${f1}_names"
#head ${f1}_names

#echo "head of ${f2}_names"
#head ${f2}_names

diff -y ${f1}_names ${f2}_names > differences.log

cat differences.log | grep ">" > right_side_differences.log

echo "head of right_side_differences.log"
head right_side_differences.log

echo "length of right side differences:"
wc -l right_side_differences.log
