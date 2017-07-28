#!/bin/bash
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##

sudo mkdir -p /data/crawl/out/
sudo mkdir -p /data/crawl/err/
sudo chown -R muse:muse /data/crawl
sudo chmod -R ug+rwx /data/crawl
