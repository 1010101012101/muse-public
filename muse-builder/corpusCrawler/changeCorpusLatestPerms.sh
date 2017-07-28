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
#today=`date "+%Y%m%d%H%M%S"`;python changeCorpusLatestPerms.py --corpus-dir-path=/data/corpus --forks=10 --debug >/data/crawl/out/$today.perms.redis.log 2>/data/crawl/err/$today.perms.redis.log
#today=`date "+%Y%m%d%H%M%S"`;python changeCorpusLatestPerms.py --corpus-dir-path=/data/corpus --forks=10 >/data/crawl/out/$today.perms.redis.log 2>/data/crawl/err/$today.perms.redis.log

# with redis
#today=`date "+%Y%m%d%H%M%S"`;python changeCorpusLatestPerms.py --corpus-dir-path=/data/corpus --forks=10 --redis --debug >/data/crawl/out/$today.perms.redis.log 2>/data/crawl/err/$today.perms.redis.log
today=`date "+%Y%m%d%H%M%S"`;python changeCorpusLatestPerms.py --corpus-dir-path=/data/corpus --forks=10 --redis >/data/crawl/out/$today.perms.redis.log 2>/data/crawl/err/$today.perms.redis.log
