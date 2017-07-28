muse-extractors
==============

This folder contains a list of MUSE Metadata Extractors which pull out metadata from each project in the corpus.  
They can be run independenty or all together.  
Each extractor will create a new json or txt metadata file associated with the project.

Running the extractors over the corpus
-------------------------------
This will run all the extractors over the corpus.
Setup to run in parallel over the corpus:

    sudo ./automateExtractors.sh /data/corpus_0to7/
    sudo ./automateExtractors.sh /data/corpus_8tof/
        

category_tagging	
-------------------------------
This will compute the topics of each project by looking for certain libraries

  topics.json
  
    {
      "Networking": 2,
      "Input-Output": 4
    }


comment_extractor
-------------------------------
Pulls out all comments embedded in the project source files.  looking for comment styles( // /* **)

  comments.json

    {
      "version": 1,
      "timestamp": "2015-05-19T01:01:49",
      "comment_data": [
    {
      "file": "./latest/radix-10.cpp",
      "comments": [
      {
        "line": 3,
        "comment": "// Author : Kurt"
      },
      {
        "line": 5,
        "comment": "// Copyright : Your copyright notice"
      },
      {
        "line": 6,
        "comment": "// Description : Hello World in C++, Ansi-style"
      },
    }


doxygen_extractor (doxygen/doxygen.json)
-------------------------------
Runs doxygen over all src files in a project that match these file endings: *.c *.cc *.cxx *.cpp *.c++ *.h *.hh *.hxx *.hpp *.h *.java )
    
    function: { name, return_type, parameter_type }
    variable: { name, type }
    class_inherited: name
    
    
filesize_extractor	
-------------------------------
each line represents a file in project with path; and associated size in bytes

    41,latest/.git/refs/heads/master
    32,latest/.git/refs/remotes/origin/HEAD
    452,latest/.git/hooks/applypatch-msg.sample
    4898,latest/.git/hooks/pre-rebase.sample
    189,latest/.git/hooks/post-update.sample
    1642,latest/.git/hooks/pre-commit.sample
    896,latest/.git/hooks/commit-msg.sample


filters_extractor
-------------------------------
Conatins top level project filters such as quality score, buildStatus, isAndriodApp, etc) 
    
filter.json
    
    {
      "hasGradleBuild": false,
      "hasGradleW": false,
      "isAndroidApp": false,
      "hasBuildLog": false,
      "hasSource": "multi_version",   (single_version, mult-version, none)
      "hasObjectFiles": "none",
      "hasBytecode": "none",
      "hasLLVM": "false",     (denotes buildbot build) 
      "hasBuildScript": "true",
      "buildStatus": "success", 
      "leidos_quality": "25.0",   (leidos quality score)

    }


import_extractor	
-------------------------------
line delimited text file to pull out all the import statements and #include statements found within .java, .c, .cpp, .h files

imports.txt

    #include <vector>
    #include <algorithm>
    #include <iostream>
    #include <iterator>
    #include "radix256.h"
    #include <iostream>
    #include <vector>
    #include <deque>
    #include <iterator>
    #include <algorithm>
    #include <iostream>
    #include <vector>
    #include <deque>
    #include <iterator>

language_extractor	
-------------------------------
pulls out all the languages and bytes associated with language for all source code
https://developer.github.com/v3/repos/#list-languages

languages.json

    {
      "C": 78769,
      "Python": 7769
    }

md5deep_extractor	
-------------------------------
each line represents a file in project with path; and associated MD5 hash

    bfc4a6b9fe1e1df6f42976e66b8006f9 /md5tmp/014f85c1-5abb-45e2-9dd4-4375eb9b441d/latest/about.py
    51b9cb86f3d9d1ea502a26cff9b09da9 /md5tmp/014f85c1-5abb-45e2-9dd4-4375eb9b441d/latest/pixmap/phone.png
    a49b6ad179bb30c54a9e3f385ff4e90d /md5tmp/014f85c1-5abb-45e2-9dd4-4375eb9b441d/latest/gtkelements.py


size_extractor	
-------------------------------
Tracks the size of project, size of metadata, and total size of everything pre archived in bytes)

totalSize.json

    {
      "project_size": 79130,
      "metadata_size": 31585,
      "total_size": 110715,
      "timestamp": 1432156587
    }


sloc_extractor
-------------------------------
uses cloc to pull sloc counts per language and in total.  calculates sloc, comment lines of code, and num of files

sloc.json

    {
      "results": {
        "header": {
          "elapsed_seconds": "0.197442054748535",
          "lines_per_second": "14201.6350243681",
          "files_per_second": "146.878536271995",
          "n_lines": "2804",
          "cloc_version": "1.60",
          "n_files": "29",
          "cloc_url": "http://cloc.sourceforge.net"
        },
        "languages": {
          "language": [
            {
              "@comment": "447",
              "@name": "Java",
              "@code": "1603",
              "@files_count": "28",
              "@blank": "623"
            },
            {
              "@comment": "3",
              "@name": "Maven",
              "@code": "115",
              "@files_count": "1",
              "@blank": "13"
            }
          ],
          "total": {
            "@comment": "450",
            "@blank": "636",
            "@sum_files": "29",
            "@code": "1718"
          }
        }
      }
    }

