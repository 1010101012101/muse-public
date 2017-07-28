#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

#today=`date "+%Y%m%d%H%M%S"`;python natesProjects.py --debug >/data/crawl/out/natesProjects$today.log 2>/data/crawl/err/natesProjects$today.log
today=`date "+%Y%m%d%H%M%S"`;python natesProjects.py >/data/crawl/out/natesProjects$today.log 2>/data/crawl/err/natesProjects$today.log
