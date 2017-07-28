MUSE - Mining and Understanding Software Enclaves
======
The goal of the Mining and Understanding Software Enclaves program (MUSE) is to realize foundational advances in the way software is built, debugged, verified, maintained, and understood.  Central to its approach is the application of mining techniques over the output of varied program analyses applied to a large and diverse multi-lingual software corpus, and the application of ideas underlying big data analytics to infer and generate useful non-trivial specifications and protocols.

Corpus Collection
-----------------

See the muse-crawler tools which we used to build our MUSE open source repository corpus from sites( Github, SourceForge, GoogleCode, Java2s, Fedora, and UCI-Maven)

Metadata Extraction
-------------------

See our muse-extractors to see the types of metadata we were extracting for each repository in the corpus

Build Tools
-----------

See our muse-builder/ to see how we handled building C/C++ open source repositores in the wild in an automated fashion.

We used UCI Java Build Framework to build Java open source repositories in the wild.
https://github.com/Mondego/SourcererJBF

Search Site
-----------

See our musesite and elasticsearch-indexer to see how we built a front end web application to view and search the corpus in an fast and efficient way and how we leveraged ElasticSearch to index our big data corpus

UCI clone detection
-------------------

We used UCI SourcererCC tool to generation clone detection analysis.  For more information:
https://github.com/Mondego/SourcererCC
