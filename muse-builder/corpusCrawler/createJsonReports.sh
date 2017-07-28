#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

today=`date "+%Y%m%d%H%M%S"`
outFile="/data/crawl/out/createJsonReports_${today}.log"
errFile="/data/crawl/err/createJsonReports_${today}.log"
# python createJsonReports.py --forks=1 --debug >$outFile 2>$errFile
python createJsonReports.py --forks=1 >$outFile 2>$errFile
