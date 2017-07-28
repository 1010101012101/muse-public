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
import os
import os.path
import sys
import time
import traceback

from elasticsearch import Elasticsearch

from locallibs import debug
from locallibs import printMsg
from locallibs import warning


###################

###
# producer process wrapper to avoid nested queries to elasticsearch
###
def findProjectsWrapper(dConfig):

    for sLanguage in ['Java']:#['Java','C','C++']:

        findProjects('languages.' + sLanguage, dConfig)

###
# producer process; finds nate's projects
###
def findProjects(sLanguage, dConfig):

    # setup elasticsearch client
    oES = Elasticsearch(dConfig['es-instance-locs'])

    lProjects = []

    iCtr = 0
    
    dQuery = {
        "query" : {
                "match_all" : {}
            },
        "fields": [sLanguage]
    }
    
    if dConfig['debug']: debug( 'func: findProjects() dQuery:', json.dumps(dQuery) ) 

    # scroll time set to 10 minutes, change as needed -- required for consistent results, the scroll token expires at the end of scroll time

    dResponse = oES.search(index=dConfig['es-project-index-name'], doc_type=dConfig['es-project-index-type'], body=json.dumps(dQuery), search_type='scan', scroll='20m', timeout='20m', lowercase_expanded_terms=False)
    sScrollId = dResponse['_scroll_id']

    if dConfig['debug']: debug('func: findProjects() (after initial search) dResponse: ', dResponse)

    if dConfig['debug']: debug('func: findProjects() search hits: ', dResponse['hits']['total'])

    #while not dResponse['timed_out'] and dResponse['hits']['hits']['total'] > 0:
    while 'timed_out' in dResponse and not dResponse['timed_out'] and 'hits' in dResponse and 'total' in dResponse['hits'] and dResponse['hits']['total'] > 0:

        dResponse = oES.scroll(scroll_id=sScrollId, scroll='20m')

        sScrollId = dResponse['_scroll_id']

        if ('hits' in dResponse['hits']) and (len(dResponse['hits']['hits']) > 0):

            if dConfig['debug']: debug('func: findProjects() scroll_id:', sScrollId, 'number of hits:', len(dResponse['hits']['hits']) )

            if dConfig['debug'] and iCtr > 10: break

            for dHit in dResponse['hits']['hits']:

                iCtr += 1

                if dConfig['debug']:

                    debug('func: findProjects()', json.dumps(dHit, indent=4))

                    if iCtr > 100: break

                # found matches

                if 'fields' in dHit and sLanguage in dHit['fields'] and '_id' in dHit: 

                    lProjects.append(dHit['_id'])

        else:

            break

    printMsg( 'func: findProjects() found ', str(iCtr), ' buildTargets, spawned process exiting...' )

    sLanguageFileName = './' + sLanguage.split('.')[1] + '.txt'

    printMsg('func: findProjects() file created: ', sLanguageFileName)

    with open(sLanguageFileName, 'w') as fLanguage:
        for sProject in sorted(lProjects):
            fLanguage.write(sProject + '\n')

    return lProjects


###
def usage():
    warning('Usage: natesProjects.py --debug')

###
def main(argv):

    dConfig = {}

    dConfig['debug'] = False

    dConfig['es-instance-locs'] = ['muse1-int','muse2-int','muse3-int']
    #dConfig['es-instance-locs'] = ['muse1-int','muse2-int']
    #dConfig['es-instance-locs'] = ['muse3-int']
    
    dConfig['es-project-index-name'] = 'corpuslite'
    dConfig['es-project-index-type'] = 'projects'

    ### command line argument handling
    options, remainder = getopt.getopt(sys.argv[1:], 'd', ['debug'])

    # debug('func: main()', 'options:', options)
    # debug('func: main()', 'remainder:', remainder)

    for opt, arg in options:

        if opt in ('-d', '--debug'):

            dConfig['debug'] = True

    iStart = time.time()

    findProjectsWrapper(dConfig)

    iEnd = time.time()

    printMsg('func: main()', 'execution time:', (iEnd - iStart), 'seconds')

###
if __name__ == "__main__":
    main(sys.argv[1:])
