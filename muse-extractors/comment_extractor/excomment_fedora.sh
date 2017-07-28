#!/bin/sh
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

if [ -d fedora ];
then
    find latest -type f | filetypefilter ~cc/comment_extractor/comment_extensions | CommentExtractor | jq . > fedora/comments.json
fi
