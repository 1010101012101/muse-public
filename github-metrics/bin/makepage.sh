#! /bin/sh
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
ROOT_DIR=/home/barnesrobe/muse/github-metrics

cd $ROOT_DIR
# Update DB
node ./js/pullMetrics.js --db "mongodb://localhost:27017/metrics" --collection github --elasticHost localhost --elasticIndex github

# Create page for public comsumption
node ./js/retrieveMetrics.js > /var/www/html/metrics.json
wkhtmltoimage --format png --load-error-handling ignore http://localhost/index.html /var/www/html/wkhtmltoimage.png
chown -R www-data.www-data /var/www/html
