##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
from bs4 import BeautifulSoup

import requests

#url = raw_input("http://www.java2s.com/Code/Jar/CatalogJar.htm")

r  = requests.get("http://www.java2s.com/Code/Jar/CatalogJar.htm")
f = open('hreffile', 'w')
data = r.text

soup = BeautifulSoup(data)

for link in soup.find_all('a'):
    currlink = link.get('href')
    print "=================================" + currlink
    if '/Code' in currlink:
	r = requests.get("http://www.java2s.com" + currlink)
	data2 = r.text
	soup2 = BeautifulSoup(data2)
	for link2 in soup2.find_all('a'):
#		if 'Download' in link2.get('href'):
		f.write(link2.get('href')+ '\n')

f.close()
