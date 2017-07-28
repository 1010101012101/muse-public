FROM dockerfile/nodejs

MAINTAINER Matthias Luebken, matthias@catalyst-zero.com

WORKDIR /home/mean

# Install Mean.JS Prerequisites
RUN npm install -g grunt-cli
RUN npm install -g grunt-contrib-coffee
RUN npm install -g grunt-contrib-watch

# Install Mean.JS packages
# Make everything available for start
ADD . /home/mean
RUN npm install
RUN make

# currently only works for development
ENV NODE_ENV development

# Port 3000 for server
# Port 35729 for livereload
EXPOSE 3000 35729
CMD ["bash"]
