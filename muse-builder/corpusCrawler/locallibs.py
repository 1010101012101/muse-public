#!/usr/bin/python
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
from __future__ import print_function

import sys

###################

###
def debug(*objs):
    print("DEBUG: ", *objs, file=sys.stdout)
    sys.stderr.flush()


###
def printMsg(*objs):
    print(*objs, file=sys.stdout)
    sys.stdout.flush()

###
def warning(*objs):
    print("WARNING: ", *objs, file=sys.stderr)
    sys.stderr.flush()
