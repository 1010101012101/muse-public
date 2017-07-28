FROM dockerfile/nodejs

MAINTAINER Roger Wuerfel, Roger.D.Wuerfel@leidos.com

# Base working directory
# is tied to NODE_PATH and working_dir in fig.yml
WORKDIR /leit/github-metrics

# Install Mean.JS Prerequisites
RUN npm install -g grunt
RUN npm install -g grunt-cli
RUN npm install -g bower

# Install node package dependencies for our project
COPY package.json /leit/github-metrics/package.json
RUN npm install

# Install bower package dependencies for our project
COPY bower.json /leit/github-metrics/bower.json
RUN bower install  --config.interactive=false --allow-root

RUN apt-get update
RUN apt-get -y install redis-tools

CMD ["make"]
