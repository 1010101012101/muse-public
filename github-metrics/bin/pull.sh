#! /bin/sh
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

node ./js/pullMetrics.js --db "mongodb://10.0.47.5:27017/metrics" --collection github --elasticHost 10.0.47.4 --elasticIndex github


