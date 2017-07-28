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

import getopt
import os
import os.path
import sys

from locallibs import debug
from locallibs import printMsg
from locallibs import warning

from projectDB import MuseProjectDB

import simplejson as json

###################

###
def usage():
    warning('Usage: identifyMultipleBuildTypeProjects.py')

###
def main(argv):

    dMp = MuseProjectDB()
    dMp.open()

    (lMultipleSameTypeProjects, lMultipleBuildTypeProjects) = dMp.findMultipleBuildTypeProjects()

    printMsg ( '# of same-type projects: ', len(lMultipleSameTypeProjects), '# of multiple-build-type projects:', len(lMultipleBuildTypeProjects) )

    with open('multipleSameTypeProjects.json', 'w') as fSameType:
        json.dump(lMultipleSameTypeProjects, fSameType, indent=4)

    with open('multipleBuildTypeProjects.json', 'w') as fMultipleType:
        json.dump(lMultipleBuildTypeProjects, fMultipleType, indent=4)

    dMp.close()        

###
if __name__ == "__main__":
    main(sys.argv[1:])
