#! /bin/sh
##
## Copyright (c) 2014-2017 Leidos.
## 
## License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
##
##
## Developed under contract #FA8750-14-C-0241
##
#ROOT_DIR=/home/muse/github-metrics

#cd $ROOT_DIR
# Update DB
node ./js/pullMetrics.js --db "mongodb://$DB_1_PORT_27017_TCP_ADDR:$DB_1_PORT_27017_TCP_PORT/metrics" --collection github --elasticHost $ES_1_PORT_9200_TCP_ADDR --elasticIndex corpuslite

# Create page for public comsumption
node ./js/retrieveMetrics.js > metrics.json
#cp /home/muse/metrics.json /var/www/html/

#wkhtmltoimage --format png --load-error-handling ignore http://localhost:8080/index.html /home/muse/musesite/public/data/wkhtmltoimage.png
#cp /home/muse/musesite/public/data/wkhtmltoimage.png /var/www/html/
#chown -R www-data.www-data /var/www/html
#scp metrics.json muse@38.100.20.212:/home/muse/musesite/public/data/
