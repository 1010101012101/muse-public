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

# redisQueue.py

import multiprocessing
import redis
import sys

from locallibs import debug
from locallibs import printMsg
from locallibs import warning

###
# Simple Queue with Redis Backend
###
class RedisQueue(object):

    ###
    # The default connection parameters are: host='localhost', port=6379, db=0
    ###
    def __init__(self, name, namespace='queue', **redis_kwargs):

        self.__db= redis.Redis(**redis_kwargs)
        self.sKey = '%s:%s' %(namespace, name)

    ###
    # dunder method for size function; returns length of queue
    ###
    def __len__(self):

        return self.qsize()

    ###
    # dunder method for determining if the queue is not empty or None
    ###
    def __nonzero__(self):

        return not self.isEmpty()

    ###
    # clear redis queue
    ###
    def flush(self):

        self.__db.delete(self.sKey)

    ###
    # Return the approximate size of the queue.
    ###
    def qsize(self):
        
        return self.__db.llen(self.sKey)

    ###
    # Return True if the queue is empty, False otherwise.
    ###
    def isEmpty(self):

        return self.qsize() == 0

    ###
    # Put item into the queue.
    ###
    def put(self, item):

        self.__db.rpush(self.sKey, item)

    ###
    # Remove and return an item from the queue. 
    # 
    # If optional args block is true and timeout is None (the default), block
    # if necessary until an item is available."""
    ###
    def get(self, block=True, timeout=None):
    
        item = None

        if block:

            item = self.__db.blpop(self.sKey, timeout=timeout)

        else:
            
            item = self.__db.lpop(self.sKey)

        if item:
        
            item = item[1]
        
        return item

###
# simple test producer
###

class redisProducer(object):

    ###
    def __init__(self, name, namespace='queue', **redis_kwargs):

        self.rq = RedisQueue(name, namespace, **redis_kwargs)
        self.rq.flush()
        self.putObjects()

    ###
    def putObjects(self):

        for i in range(1,10):

            self.rq.put('hello world')

        self.rq.put('done')
        self.rq.put('done')

###
# simple consumer
###

class redisConsumer(object):

    ###
    def __init__(self, consumerName, name, namespace='queue', **redis_kwargs):

        self.sConsumerName = consumerName
        self.rq = RedisQueue(name, namespace, **redis_kwargs)
        self.getObjects()

    ###
    def getObjects(self):

        bDone = False

        while not bDone:

            item = self.rq.get()

            printMsg(self.sConsumerName,':item:', item)

            if item == 'done':

                bDone = True

###
def runConsumer(tTuple):

    (sConsumerName, sName) = tTuple

    rc = redisConsumer(sConsumerName, sName)

###
def main(argv):

    sName = 'muse:projects'

    rp = redisProducer(sName)
    iForks = 2

    oPool = multiprocessing.Pool(processes=iForks)

    lArgs = [('consumer1',sName), ('consumer2',sName)]

    ### do work -- use pool of workers to process queue contents
    oPool.map(runConsumer, lArgs)

    oPool.close()
    oPool.join()

###
if __name__ == "__main__":
    main(sys.argv[1:])