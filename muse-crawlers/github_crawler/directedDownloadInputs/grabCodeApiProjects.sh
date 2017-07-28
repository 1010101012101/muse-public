#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
# Grab projects from Github Code API given search terms
# store projects found in text file

for i in `seq 1 $1`; do
    wget -O - "https://github.com/search?utf8=✓?p="$i"&q=\"geometry\"+language%3AC++language%3AC%2B%2B+language%3AJava&type=Code&ref=searchresults" | grep "blob/" | cut -d '/' -f 2-3 >> geometry.txt 
    sleep 10
done

