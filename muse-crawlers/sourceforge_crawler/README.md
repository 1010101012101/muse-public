sourceforge-cralwer
===================

Dependencies
------------

Python dependencies: 

    pip install bs4 redis requests urllib python-magic


Linux packages needed

    python-pip unzip unrar bzip2 gzip p7zip-full redis-server mongodb


How to Run:
-----------

Crawls SourceForge repository and downloads all projects to the specifed output folder.  The crawler crawls sequentitally by projectID and you must specify a starting projectID. Redis is used to map SF projectIDs to our uuid4 unique ids.

cd muse-crawlers/

    usage: startMUSECrawler.py --sourceforge --out [path] [startID]   

    positional arguments:
      startID          the sourceforge project id to start crawling from

    optional arguments:
      -h, --help       show this help message and exit
      --out [path]  specify which folder to download projects to (required)
