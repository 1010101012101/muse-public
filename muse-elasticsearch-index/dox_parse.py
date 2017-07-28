##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
import json
import pprint
pp = pprint.PrettyPrinter(indent=2)

filename = "/data/corpus/e/5/a/2/c/0/b/c/e5a2c0bc-cdd7-11e4-9006-7fd62f2c7ef3/doxygen/doxygen.json"
data = json.load(open(filename, "rb"))
for item in data["doxygen"]["compounddef"]:
    if item["@kind"] == "file":
        pp.pprint(item)
        print "-----------------------------------------------"
