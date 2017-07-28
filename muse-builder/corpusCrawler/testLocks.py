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

import datetime
import getopt
import json
import multiprocessing
import os
import os.path
import sys
import time
import traceback

from locallibs import debug
from locallibs import printMsg
from locallibs import warning

###################

###################

lock = None
def initialize_lock(l):
   global lock
   lock = l

###
# test consumer
###
def test(tTup):

    (sMsg, iProcId) = tTup

    for iCtr in range(0,5):

        lock.acquire()

        time.sleep(1)
        debug('func: test():', sMsg, iProcId, 'msg #', iCtr)

        lock.release()

###
def usage():
    warning('Usage: testLocks.py')

###
def main(argv):

    iForks = 10
    iStart = time.time()

    ### setup consumers

    lConsumerArgs = []

    # create a locking semaphore for mutex
    lock = multiprocessing.Lock()

    for iCtr in range(0, iForks):

        lConsumerArgs.append( ("lock testing procId", iCtr) )

    # create pool of workers -- number of workers equals the number of search strings to be processed
    oConsumerPool = multiprocessing.Pool( processes=iForks, initializer=initialize_lock, initargs=(lock,) )

    ### do work -- use pool of workers to search for each search string in muse-corpus-source es index
    oConsumerPool.map(test, lConsumerArgs)

    oConsumerPool.close()
    oConsumerPool.join()

    # processBuildTargets( (dSearchStrings[ dConfig['queueBuildType'] ], 0, dArgs, dConfig) ) 

    debug('func: main()', "all processes completed") 

    iEnd = time.time()

    printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
