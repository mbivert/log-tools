.PHONY: help
help:
	@echo "install                  : install   TODO"
	@echo "uninstall                : uninstall TODO"
	@echo "tests                    : run automated tests"
	@echo "get-ip2location key= ... : fetch an IP2LOCATION-LITE-DB1.CSV from"
	@echo "                          ip2location.com using the given key"

.PHONY: tests
tests:
	@echo Running tests...
	@perl ./tests/*.t
	@sh   ./tests.sh

.PHONY: get-ip2location
get-ip2location:
	@echo Downloading an ip2location.csv...
	@sh ./get-ip2location.sh ${key}
