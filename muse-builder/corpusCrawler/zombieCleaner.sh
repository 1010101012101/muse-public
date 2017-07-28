#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

# zombie cleaner
function cleanup()
{
    local pids=`jobs -p`
    if [[ "$pids" != "" ]]; then
        kill $pids >/dev/null 2>/dev/null
    fi

    sleep 5

    local pids=`jobs -p`
    if [[ "$pids" != "" ]]; then
        kill -9 $pids >/dev/null 2>/dev/null
    fi

    sleep 5
}

trap cleanup EXIT

### script payload

/tester.sh&
/tester.sh&
/tester.sh&

wait