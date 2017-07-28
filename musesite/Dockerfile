FROM dockerfile/nodejs

MAINTAINER Matthias Luebken, matthias@catalyst-zero.com

# Base working directory
# is tied to NODE_PATH and working_dir in fig.yml
WORKDIR /leit/nodeapp

# Install Mean.JS Prerequisites
RUN npm install -g grunt
RUN npm install -g grunt-cli
RUN npm install -g bower

# Install node package dependencies for our project
COPY package.json /leit/nodeapp/package.json
RUN npm install

# Copy in the bower files that defined our client side dependencies
COPY .bowerrc /leit/nodeapp/.bowerrc
COPY bower.json /leit/nodeapp/bower.json

# Allow bower to use git via https instead of just git protocol
RUN git config --global url."https://".insteadOf git://

# Install the package dependencies for the Angular, client side
RUN bower install --config.interactive=false --allow-root

# Copy the main node.js server entry point
COPY server.js /leit/nodeapp/server.js

# currently only works for development
ENV NODE_ENV development

# Port 3000 for server
EXPOSE 3000
CMD ["bash"]
