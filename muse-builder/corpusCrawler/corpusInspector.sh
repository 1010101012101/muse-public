#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# without redis
#today=`date "+%Y%m%d%H%M%S"`;python corpusInspector.py --corpus-dir-path=/data/corpus --forks=5 --debug >/data/crawl/out/corpusInspector_${today}.log 2>/data/crawl/err/corpusInspector_${today}.log
#today=`date "+%Y%m%d%H%M%S"`;python corpusInspector.py --corpus-dir-path=/data/corpus --forks=5 >/data/crawl/out/corpusInspector_${today}.log 2>/data/crawl/err/corpusInspector_${today}.log

# with redis
#today=`date "+%Y%m%d%H%M%S"`;python corpusInspector.py --corpus-dir-path=/data/corpus_0to7 --forks=10 --redis --debug >/data/crawl/out/corpusInspector_${today}.redis.log 2>/data/crawl/err/corpusInspector_${today}.redis.log
today=`date "+%Y%m%d%H%M%S"`;python corpusInspector.py --corpus-dir-path=/data/corpus_8tof --forks=10 --redis >/data/crawl/out/corpusInspector_${today}.redis.log 2>/data/crawl/err/corpusInspector_${today}.redis.log
