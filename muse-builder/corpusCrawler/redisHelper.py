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
    def __init__(self, name, name2=None, namespace='queue', **redis_kwargs):

        self.__db= redis.Redis(**redis_kwargs)
        self.sKey = '%s:%s' %(namespace, name)

        self.sKey2 = None

        if name2:

            self.sKey2 = '%s:%s' %(namespace, name2)

    ###
    # dunder method for size function; returns length of queue
    ###
    def __len__(self):

        return self.size()

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
    def size(self):
        
        return self.__db.llen(self.sKey)

    ###
    # Return True if the queue is empty, False otherwise.
    ###
    def isEmpty(self):

        return self.size() == 0

    ###
    # Peek at head item in queue.
    ###
    def peek(self):

        item = self.__db.lrange(self.sKey, 0, 0)

        if item:
        
            item = item[0]

        return item

    ###
    # Put item into the queue.
    ###
    def put(self, item):

        self.__db.lpush(self.sKey, item)

    ###
    # Remove and return an item from the queue. 
    # 
    # If optional args block is true and timeout is None (the default), block
    # if necessary until an item is available."""
    ###
    def get(self, block=True, timeout=None):
    
        item = None

        if block:

            item = self.__db.brpop(self.sKey, timeout=timeout)

        else:
            
            item = self.__db.rpop(self.sKey)

        if item:
        
            item = item[1]
        
        return item

    ###
    # Remove and return an item from the queue. 
    # 
    # If optional args block is true and timeout is None (the default), block
    # if necessary until an item is available."""
    ###
    def getnpush(self, block=True, timeout=None):
    
        item = None

        if block:

            item = self.__db.brpoplpush(src=self.sKey, dst=self.sKey2, timeout=timeout)

        else:
            
            item = self.__db.rpoplpush(src=self.sKey, dst=self.sKey2)
        
        return item

    ###
    # Removes item from secondary list when we're done processing
    ###
    def done(self, value, num=0):
    
        self.__db.lrem(name=self.sKey2, value=value, num=num)

###
# Simple Queue with Redis Backend
###
class RedisSet(object):

    ###
    # The default connection parameters are: host='localhost', port=6379, db=0
    ###
    def __init__(self, name, namespace='set', **redis_kwargs):

        self.__db= redis.Redis(**redis_kwargs)
        self.sKey = '%s:%s' %(namespace, name)

    ###
    # dunder method for set membership; returns if item is in the set
    ###

    def __contains__(self, item):

        return self.__db.sismember(self.sKey, item)

    ###
    # dunder method for size function; returns length of set
    ###
    def __len__(self):

        return self.size()

    ###
    # dunder method for determining if the set is not empty or None
    ###
    def __nonzero__(self):

        return not self.isEmpty()

    ###
    # clear redis set
    ###
    def flush(self):

        self.__db.delete(self.sKey)

    ###
    # Return the approximate size of the set.
    ###
    def size(self):
        
        return self.__db.scard(self.sKey)

    ###
    # Return True if the set is empty, False otherwise.
    ###
    def isEmpty(self):

        return self.__db.scard() == 0

    ###
    # Put item into the queue.
    ###
    def put(self, item):

        self.__db.sadd(self.sKey, item)

    ###
    # Remove and return an item from the set. 
    ###
    def get(self):
    
        item = self.__db.spop(self.sKey)
        
        return item

###
# simple test producer
###

class redisProducer(object):

    ###
    #def __init__(self, name, namespace='queue', **redis_kwargs):
    def __init__(self, name, namespace='set', **redis_kwargs):

        #self.rq = RedisQueue(name, namespace, **redis_kwargs)
        self.rq = RedisSet(name, namespace, **redis_kwargs)
        self.rq.flush()
        self.putObjects()

    ###
    def putObjects(self):

        for i in range(1,10):

            self.rq.put('hello world')

###
# simple consumer
###

class redisConsumer(object):

    ###
    #def __init__(self, consumerName, name, namespace='queue', **redis_kwargs):
    def __init__(self, consumerName, name, namespace='set', **redis_kwargs):

        self.sConsumerName = consumerName
        #self.rq = RedisQueue(name, namespace, **redis_kwargs)
        self.rq = RedisSet(name, namespace, **redis_kwargs)
        self.getObjects()

    ###
    def getObjects(self):

        while self.rq:

            item = self.rq.get()

            printMsg(self.sConsumerName,':item:', item)

###
def runConsumer(tTuple):

    (sConsumerName, sName) = tTuple

    rc = redisConsumer(sConsumerName, sName, host='38.100.20.211', port=12345)

###
def main(argv):

    sName = 'muse:projects'

    rp = redisProducer(sName, host='38.100.20.211', port=12345)
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