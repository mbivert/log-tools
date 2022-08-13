.PHONY: all
all: logtweak logtag iploc

.PHONY: help
help:
	@echo "all                      : build logtweak, logtag"
	@echo "clean                    : removed compiled files"
	@echo "tests                    : run automated tests"
	@echo "get-ip2location key= ... : fetch an IP2LOCATION-LITE-DB1.CSV from"
	@echo "                           ip2location.com using the given key"

.PHONY: tests
tests: logtag logtweak
	@echo Running tests...
	@go test -v tweak_test.go ftests.go tweak.go
	@go test -v iplocate_test.go ftests.go iplocate.go
	@sh ./tests.sh

.PHONY: get-ip2location
get-ip2location:
	@echo Downloading an ip2location.csv...
	@sh ./get-ip2location.sh ${key}

logtag:   logtag.go   tag.go
logtweak: logtweak.go tweak.go iplocate.go
iploc:    iploc.go             iplocate.go

logtag logtweak iploc:
	@echo Building $@...
	go build $^

.PHONY: clean
clean:
	@echo Remove compiled binaries...
	@rm -f logtag logtweak iploc
