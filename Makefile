SHELL=/bin/bash
DOMAIN="ipfs.io"

IPFSLOCAL="http://localhost:8080/ipfs/"
IPFSGATEWAY="https://ipfs.io/ipfs/"
NPM=npm
NPMBIN=./node_modules/.bin
OUTPUTDIR=public

ifeq ($(DEBUG), true)
	PREPEND=
	APPEND=
else
	PREPEND=@
	APPEND=1>/dev/null
endif

build: clean install lint js css minify
	$(PREPEND)hugo && \
	echo "" && \
	echo "Site built out to ./public dir"

help:
	@echo 'Makefile for contribs, a hugo built static site.                                            '
	@echo '                                                                                            '
	@echo 'Usage:                                                                                      '
	@echo '  make                    Build the optimised site to ./$(OUTPUTDIR)                        '
	@echo '  make serve              Preview the production ready site at http://localhost:1313        '
	@echo '  make lint               Check your JS and CSS are ok                                      '
	@echo '  make test               Test the scripts                                                  '
	@echo '  make js                 Browserify the *.js to ./static/js                                '
	@echo '  make css                Compile the *.less to ./static/css                                '
	@echo '  make minify             Optimise all the things!                                          '
	@echo '  make dev                Start a hot-reloding dev server on http://localhost:1313          '
	@echo '  make deploy             Add the website to your local IPFS node                           '
	@echo '  make clean              Remove the generated files                                        '
	@echo '                                                                                            '
	@echo '  DEBUG=true make [command] for increased verbosity                                         '

serve: install lint js css minify
	$(PREPEND)hugo server

node_modules:
	$(PREPEND)$(NPM) i $(APPEND)

install: node_modules
	$(PREPEND)[ -d static/js ] || mkdir -p static/js && \
	[ -d static/css ] || mkdir -p static/css

lint: install
	$(PREPEND)$(NPMBIN)/standard && $(NPMBIN)/lessc --lint less/*

test: lint
	$(PREPEND)$(NPMBIN)/tape 'scripts/**/*.test.js'

js: install
	$(PREPEND)$(NPMBIN)/browserify js/main.js -o static/js/bundle.js $(APPEND)

css: install
	$(PREPEND)$(NPMBIN)/lessc --clean-css --autoprefix less/main.less static/css/main.css $(APPEND)

minify: install minify-js

minify-js: install
	$(PREPEND)find static/js -name '*.js' -exec $(NPMBIN)/uglifyjs {} --compress --output {} $(APPEND) \;

dev: install js css
	$(PREPEND)( \
		$(NPMBIN)/nodemon --watch less --exec "$(NPMBIN)/lessc --clean-css --autoprefix less/main.less static/css/main.css" & \
		$(NPMBIN)/watchify js/main.js -o static/js/bundle.js & \
		hugo server -w \
	)

deploy:
	ipfs add -r -q $(OUTPUTDIR) | tail -n1 >versions/current ; \
	cat versions/current >>versions/history ; \
	export hash=`cat versions/current`; \
		echo ""; \
		echo "published website:"; \
		echo "- $(IPFSLOCAL)$$hash"; \
		echo "- $(IPFSGATEWAY)$$hash"; \
		echo ""; \
		echo "next steps:"; \
		echo "- ipfs pin add -r /ipfs/$$hash"; \

clean:
	$(PREPEND)[ ! -d $(OUTPUTDIR) ] || rm -rf $(OUTPUTDIR) && \
	[ ! -d static/js ] || rm -rf static/js/* && \
	[ ! -d static/css ] || rm -rf static/css/*

.PHONY: build help install lint test js css minify minify-js dev deploy clean
