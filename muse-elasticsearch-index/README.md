elasticsearch-indexer
=====================
This process controls how metadata from the corpus is indexed into ElasticSearch and made available in the MUSE search site.

ES Corpus Index
---------------
The main corpus index that we are currently using is: 

	corpus12aug
	
view all ES indices

	curl 'localhost:9200/_cat/indices?v'


ES Corpus Mapping
-----------------
Current MUSE ES mapping:

	muse-es-mapping.json

View ES index mapping

	curl 'localhost:9200/<index_name>/_mapping?v'


reset_index.py   (never perform on our active index) (use for testing)
--------------
This initializes a new ES index (and when given the -o or --overwrite option) 
will completely erase and reinitialize an existing index(be careful).  
It will also setup a new ES index with our mapping correctly 
(uses mapping: "muse-es-mapping.json" under the hood).  
Note: <index_name> must be all lower case.

	Usage:  sudo python reset_index.py <index_name>

index_corpus.py
---------

	./index_corpus.py corpus12aug 07_13_17_CorpusProjects.txt
	
	usage: ingest.py [-h] [-np] [-nf] [-nc] [-x X_OF] [-y OF_Y] index dir_list

	positional arguments:
	index elasticsearch index name
	dir_list filename containing list of project dirs
	optional arguments:
	-h, --help show this help message and exit
	-np, --noproject Do not index projects records
	-nf, --nofile Do not index file records
	-nc, --nocommit Do not index commit records
	-x X_OF, --x_of X_OF parallel script this is (0 indexed)
	-y OF_Y, --of_y OF_Y Scripts you intend to run in parallel
	
Output
	Two log files are created per script. The success log persists between runs and anything contained within is skipped. The failed log is recreated each time to indicate which projects are having issue.  Put another way the successful projects are never repeated but the failed ones are reattempted on each run (and their failure noted).  The idea is that we may be able to fix whatever is broken and rerun.  Clear or remove success log to re-index everything.

	 <index_name>_0_of_1_success.log
	 <index_name>_0_of_1_failed.log

Running in Parallel
when running in parallel each "slice" gets its own log filename so be careful switching up the number of slices 
(if you aren't looking to repeat work because of the now new/empty success log).

	Eg.  "./index_corpus.py -x 0 -y2 …" and "./ingest.py –x 1 –y 2 …" would split projects between the two scripts.
	
Can be run in parallel b/c the bottleneck is usually the file system and/or ElasticSearch and 
we are just trying to make sure we are getting work done while waiting for I/O
 
When things are working well I didn't see much improvement past 5 in parallel (I would estimate maybe running 3-4 times baseline speed)


delete_project.py
------------------
Remove projects from an index (given a list of project uuids)

	sudo python delete_project.py corpus12aug removeIDs2.txt


Add a New property to mapping/ES
--------------------------------

Update our current ES index(corpus12aug) to add new parameter:

	curl -XPUT 'localhost:9200/corpus12aug/_mapping/project' -d '{ "properties": { "<param_name>": { "type": "<param_type>", "index": "not_analyzed" } } }'

Update original mapping file so updates can be applied on a new index if created.

	vi muse-es-mapping.json; 

	Add new parameter inline:
	{
		"<param_name>": {
		"type": "<param_type>",
		"index": "not_analyzed"
	},
	
Re-index the corpus to grab new parameter from data
