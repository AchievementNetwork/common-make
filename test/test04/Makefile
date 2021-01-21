PROJECT=$(shell basename $(CURDIR))
COPYTARGETS=data/foo data/bar

pre-build::
	@echo "This should show up once pre-build"

post-build::
	@echo "This should show up once post-build"

include ../../go-common.mk
include ../../copy-common.mk
