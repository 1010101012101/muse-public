google-crawler
==============

GoogleCode crawler is based on data provided by www.FlossMole.org.  
They routinely scrap and pull out data from GoogleCode projects into their database and provide a flat file of projects with associated metadata to the public.  The last time FlossMole scrapped GoogleCode was 2012 and the file we are using to crawl GC can be found here: http://flossdata.syr.edu/data/gc/2012/.

They provide for each GC project:

    # proj_name, 
    # datasource_id, 
    # code_license, 
    # code_url, 
    # activity_level, 
    # content_license, 
    # content_url, 
    # project_summary, 
    # project_description
    
We crawl GC project repositoreis based on the "proj_name" and are assuming an svn repo only.  
Latest code is grabed via:  svn checkout http://{proj_name}.googlecode.com/svn/trunk/ $dest_path/latest
associated metadata fields are stored in a "project.properties" file at the root of each project.
 
Usage:
------

    sudo ./googleCrawler.sh gcProjectInfo2012-Nov-trim3.dat /data/corpus_0to7/googlecode3/
