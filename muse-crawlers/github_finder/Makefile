.PHONY: doc

all: node_modules
	grunt

node_modules:
	npm install

doc:
	docco --output doc src/*.coffee
	open doc/index.html

install:
	npm install -g .

clean:
	rm -rf node_modules
	rm -rf js