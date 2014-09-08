.PHONY: all

watch:
	coffee -cbw public/library.coffee

all:
	coffee -cb public/library.coffee
