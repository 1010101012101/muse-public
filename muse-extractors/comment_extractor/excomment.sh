#!/bin/sh
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

site = $(cat index.json | jq .site | sed sed s/\"//g)

if [ -d $site ];
then
    find latest -type f | filetypefilter ~cc/comment_extractor/comment_extensions | CommentExtractor | jq . > $site/comments.json
fi
