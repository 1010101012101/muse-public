##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
import os
root_dir = '/data/corpus/'

for root, dirs, files in os.walk(root_dir):
   for dir_name in dirs:
       if len(dir_name) == 36 and len(dir_name.split('-')) == 5:
           print ",".join((root, dir_name))
