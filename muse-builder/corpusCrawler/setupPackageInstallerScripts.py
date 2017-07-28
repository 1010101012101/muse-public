#!/usr/bin/python
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

import datetime
import getopt
import json
import os
import os.path
import sys
import time
import traceback
import yaml

###################

###
def createScript(sOutputScriptDir, sOS, iScriptCtr, lCurrPkgs):

    sScriptName = os.path.join(sOutputScriptDir, 'installPkgs-' + sOS + '_' + str(iScriptCtr) + '.sh')

    sOutput = "#!/bin/bash\n\n"

    for sPkg in lCurrPkgs:

        sOutput += "echo \" ####### installing " + sPkg + " ######\"\n"
        sOutput += "apt-get install -y " + sPkg + "\n\n"

    sOutput += "# running true to initialize $? to ensure bash doesn't error out if a packages don't install for some reason\n"
    sOutput += "true\n"

    with open(sScriptName, "w") as fOutputScript:
    
        fOutputScript.write(sOutput)

    return sScriptName

###
def usage():
    print 'Usage: setupPackageInstallerScripts.py --num-packages=1000 --path-to-input-pillar=/srv/pillar/builderPackages.sls --path-to-output-pillar=/srv/pillar/builderScripts.sls --path-to-output-scripts=/srv/salt/builder/files --os=ubuntu14 --debug'

###
def main(argv):

    # default argument values
    iNumPkgs = 1000
    sInputPillarPath = '/srv/pillar/builderPackages.sls'
    sOutputPillarPath = '/srv/pillar/builderScripts.sls'
    sOutputScriptDir = '/srv/salt/builder/files'
    sOS = 'ubuntu14'
    bDebug = False

    bError = False

    ### command line argument handling
    options, remainder = getopt.getopt(sys.argv[1:], 'n:i:p:s:o:d', ['num-packages=','path-to-input-pillar=','path-to-output-pillar','path-to-output-scripts','os=','debug'])

    # debug('func: main()', 'options:', options)
    # debug('func: main()', 'remainder:', remainder)

    for opt, arg in options:

        if opt in ('-n', '--num-packages'):

            try:
            
                iNumPkgs = int(arg)

            except ValueError as e:

                bError = True

        elif opt in ('-i', '--path-to-input-pillar'):

            sInputPillarPath = arg

            if not os.path.isfile(sInputPillarPath):

                bError = True
                print 'error: sInputPillarPath is not a file'

        elif opt in ('-p', '--path-to-output-pillar'):

            sOutputPillarPath = arg 

            if not os.path.isfile(sOutputPillarPath) and not os.path.isdir( os.path.dirname(sOutputPillarPath) ):

                bError = True
                print 'error: sOutputPillarPath is not a file and its parent directory doesn\'t exist'

        elif opt in ('-s', '--path-to-output-scripts'):

            sOutputScriptDir = arg

            if not os.path.isdir(sOutputScriptDir):

                bError = True
                print 'error: sOutputScriptDir is not a valid directory'

        elif opt in ('-o', '--os'):

            sOS = arg

        if opt in ('-d', '--debug'):

            dConfig['debug'] = True

    dInputPillar = {}

    # try to load os-specific packages from the pillar yaml file
    if not bError:

        fInputPillar = open(sInputPillarPath, 'r')
        dInputPillar = yaml.load(fInputPillar)

        print 'dInputPillar:', json.dumps(dInputPillar, indent=4), 'dInputPillar.keys():', dInputPillar.keys()

        print 'dInputPillar[\'builderPackages\'].keys():', dInputPillar['builderPackages'].keys()

        if 'builderPackages' not in dInputPillar or sOS not in dInputPillar['builderPackages'].keys():

            bError = True
            print 'error: \'builderPackages\' not found in ' + sInputPillarPath + ' or ' + sOS + ' not found in sInputPillarPath[\'builderPackages\']'

    if bError: usage()
    else:

        lPkgs = dInputPillar['builderPackages'][sOS]

        iPkgCtr = 0
        lCurrPkgs = []
        lScriptNames = []
        iScriptCtr = 0

        for sPkg in lPkgs:

            lCurrPkgs.append(sPkg)

            iPkgCtr = iPkgCtr + 1

            if iPkgCtr >= iNumPkgs:

                iScriptCtr = iScriptCtr + 1
                lScriptNames.append( createScript(sOutputScriptDir, sOS, iScriptCtr, lCurrPkgs) )
                lCurrPkgs = []
                iPkgCtr = 0

        # pickup stragglers
        if len(lCurrPkgs) > 0:

            iScriptCtr = iScriptCtr + 1
            lScriptNames.append( createScript(sOutputScriptDir, sOS, iScriptCtr, lCurrPkgs) )

        dScripts = {}
        dScripts['builderScripts'] = { sOS : lScriptNames }

        if bDebug: ( 'func: main() dScripts:', json.dumps(dScripts, indent=4) ) 

        with open(sOutputPillarPath, 'w') as fOutputPillar:

            fOutputPillar.write( yaml.dump(dScripts, default_flow_style=True) )

###
if __name__ == "__main__":
    main(sys.argv[1:])
