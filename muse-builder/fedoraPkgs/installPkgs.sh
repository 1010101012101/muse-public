#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

f1=right_side_differences.log

for pkg in `cat right_side_differences.log | cut -d ' ' -f 3`
do
	echo "installing ****${pkg}*****"
	yum install -y $pkg
done
