##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
from bs4 import BeautifulSoup

import urllib
import urllib2
import requests

user_agent = 'Mozilla/5.0 (X11; Linux i586; rv:31.0) Gecko/20100101 Firefox/31.0'
headers = { 'User-Agent' : user_agent }

f = open('zipfile', 'a', 1)
with open('hreffile-sorted-download3','r') as d:
    for line in d:
	print "**** " + line
	url = "http://java2s.com" + line
	r = urllib2.Request(url, None, headers)
	html = urllib2.urlopen(r)
#	r = requests.get("http://www.java2s.com" + line)
#	data = r.text
#	print data
	soup = BeautifulSoup(html)
	for link in soup.find_all('a'):
  		currlink = link.get('href')
#		print "=" + currlink
		if 'zip' in currlink:
			print "got: " + currlink
			f.write(currlink + '\n')
#	r = requests.get("http://www.java2s.com" + currlink)
#	data2 = r.text
#	soup2 = BeautifulSoup(data2)
#	for link2 in soup2.find_all('a'):
#		if 'Download' in link2.get('href'):
#		f.write(link2.get('href')+ '\n')
#
f.close()
