#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

logDir="/home/sbhattacharyya/corpusCrawler/logs"

# for buildOS in 'ubuntu14' 'ubuntu12' 'fedora20' 'fedora21'
for buildOS in 'ubuntu14'
#for buildOS in 'ubuntu12'
# for buildOS in 'fedora20' 'fedora21'
#for buildOS in 'fedora21'
# for buildOS in 'fedora20'
do

	today=`date "+%Y_%m_%d_%H_%M_%S"`
	outFile="${logDir}/buildProjectsByType_${buildOS}_${today}.out"
	errFile="${logDir}/buildProjectsByType_${buildOS}_${today}.err"

	echo "using buildOS ${buildOS}"

	#python buildProjectsByType_cyber.py --forks=1 --os="${buildOS}" --debug-flags --rebuild >>$outFile 2>>$errFile
	#python buildProjectsByType.py --forks=1 --os="${buildOS}" --debug --rebuild >>$outFile 2>>$errFile
	python buildProjectsByType.py --forks=10 --os="${buildOS}" >>$outFile 2>>$errFile

	###############################################################################################################

done
