PROJECT=$(shell basename $(CURDIR))

build:
	@mkdir -p build
	touch build/test05
	chmod u+x build/test05

test:

testcover:
	touch coverage.html

%: force
	@$(MAKE) PROJECT=$(PROJECT) -f ../../go-common.mk $@

force: ;

.PHONY: build force test testcover
