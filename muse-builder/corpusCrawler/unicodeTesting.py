#!/usr/bin/python
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

import json
import os
import os.path
import socket
import sys
import time
import traceback

###################

###
def parseBuildOutput(sFile):

    if os.path.isfile(sFile):

        with open(sFile, 'r') as fBuilderFile:

            # get file input and trim unnecessary whitespace before/after
            sBuffer = ( fBuilderFile.read() ).strip()

        try:

            sDecodedFile = sBuffer.decode('utf-8')
            sEncodedWith = 'utf-8'

        except (ValueError, UnicodeDecodeError) as e:

            try:

                sDecodedFile = sBuffer.decode('latin-1')
                sEncodedWith = 'latin-1'

            except (ValueError, UnicodeDecodeError) as e:

                try:

                    sDecodedFile = sBuffer.decode('utf-16')
                    sEncodedWith = 'utf-16'

                except (ValueError, UnicodeDecodeError) as e:

                    print 'func parseBuildOutput():', 'sFile:', sFile, 'dBuffer:', dBuffer, 'utf-8, latin-1, and utf-16 decoding failed', 'exception:', e

                    sDecodedFile = ''
                    sEncodedWith = ''
                    sBuffer = ''

        print 'sFile:', sFile, 'sEncodedWith:', sEncodedWith 

###
def main(argv):

    lDirs = []

    for iCtr in range(0,10):

        lDirs.append('/data/builder/musebuilder-ubuntu14-muse1_' + str(iCtr) + '/output/')

    for sParentDir in lDirs:

        print 'sParentDir:', sParentDir

        if os.path.isdir(sParentDir):

            for sRoot, lSubDirs, lFiles in os.walk(sParentDir):

                for sFile in lFiles:

                    if sFile.startswith('std'):

                        print 'sFile:', os.path.join(sRoot, sFile)
                        parseBuildOutput(os.path.join(sRoot, sFile))

###
if __name__ == "__main__":
    main(sys.argv[1:])
