# This file is part of the ANet Engineering Common Make infrastructure
#
# Please do not edit it in place if this is a local copy outside of the common-make
# repository.  Rather, override the external variable and targets in your Makefile.
# If you have an enhancement, please submit a pull request against
#   https://github.com/AchievementNetwork/common-make
# and then update your local copy once it is approved

## Variables

## External variables
# These may be overridden by the repo Makefile

# Default project name
PROJECT ?= $(shell basename $(CURDIR))

# Standard go variables
GO ?= go
GOSRC ?= $(shell find . -name '*.go')
GOTARGETS ?= $(PROJECT)
GOROOTTARGET ?=
GOFLAGS ?=
GOTESTTARGET ?= ./...
GOTESTFLAGS ?= -v -race
GOCMDDIR ?= ./cmd

# Default output directory for executables and associated (copied) files
BUILDDIR ?= build

## Internal variables
# DO NOT OVERRIDE
ifdef GOROOTTARGET
_GO_BUILD_TARGETS := $(addprefix $(BUILDDIR)/,$(filter-out $(GOROOTTARGET),$(GOTARGETS)))
_GO_ROOT_BUILD_TARGET := $(addprefix $(BUILDDIR)/,$(GOROOTTARGET))
else
_GO_BUILD_TARGETS := $(addprefix $(BUILDDIR)/,$(GOTARGETS))
_GO_ROOT_BUILD_TARGET :=
endif

## Targets

.PHONY: build clean lint test testcover
.PHONY: pre-build standard-build post-build
.PHONY: pre-clean standard-clean post-clean
.PHONY: pre-lint standard-lint post-lint
.PHONY: pre-test standard-test post-test
.PHONY: pre-testcover standard-testcover post-testcover
.PHONY: _checkcommonupdate _commonupdate

## External targets
# These may be overridden and used in repo Makefiles

# Build all targets
build:: pre-build standard-build post-build

pre-build::

standard-build:: $(_GO_ROOT_BUILD_TARGET) $(_GO_BUILD_TARGETS)

post-build::

# Clean up build artifacts
clean:: pre-clean standard-clean post-clean

pre-clean::

standard-clean::
	-$(RM) $(_GO_BUILD_TARGETS)
ifdef _GO_ROOT_BUILD_TARGET
	-$(RM) $(_GO_ROOT_BUILD_TARGET)
endif
	-$(RM) coverage.raw coverage.html
	-rmdir $(BUILDDIR)

post-clean::

# Lint code
lint:: pre-lint standard-lint post-lint

pre-lint::

standard-lint::
	@which golangci-lint > /dev/null 2>&1 || \
		$(GO) get github.com/golangci/golangci-lint/cmd/golangci-lint
	golangci-lint run

post-lint::

# Run unit tests
test:: pre-test standard-test post-test

pre-test::

standard-test::
	$(GO) test $(GOTESTFLAGS) $(GOTESTTARGET)

post-test::

testcover:: pre-testcover standard-testcover post-testcover

pre-testcover::

standard-testcover:: coverage.html

post-testcover::

# External targets that can be used, but should not be overridden

_checkcommonupdate::
	@TMP_FILE=`mktemp go-common.mk.XXXXXX`; \
		curl -o $${TMP_FILE} -s -S -L https://raw.github.com/AchievementNetwork/common-make/main/go-common.mk; \
		if [ $$? -ne 0 ]; then echo "Update check failed"; exit 1; fi; \
		diff -b --brief go-common.mk $${TMP_FILE} > /dev/null; \
		if [ $$? -ne 0 ]; then echo "It looks like go-common.mk is out of date.  Please run \`make _commonupdate\`"; else echo "go-common.mk up to date"; fi; \
		$(RM) $${TMP_FILE}

_commonupdate::
	@TMP_FILE=`mktemp go-common.mk.XXXXXX`; \
		curl -o $${TMP_FILE} -s -S -L https://raw.github.com/AchievementNetwork/common-make/main/go-common.mk; \
		if [ $$? -ne 0 ]; then echo "Update failed"; exit 1; fi; \
		mv $${TMP_FILE} go-common.mk; \
		echo "Please test and then commit the new version of go-common.mk"

## Internal targets
# DO NOT OVERRIDE OR USE
# Overriding may yield undefined results
# Names may change at any time

# Test coverage files
coverage.raw:
	$(GO) test $(GOTESTFLAGS) -coverprofile=$@ $(GOTESTTARGET)

coverage.html: coverage.raw
	$(GO) tool cover -html=$< -o $@

# Go executables
$(_GO_ROOT_BUILD_TARGET): $(GOSRC)
	@-mkdir build 2> /dev/null
	$(GO) generate ./...
	$(GO) get ./...
	$(GO) build $(GOFLAGS) -o $@ .

$(_GO_BUILD_TARGETS): $(GOSRC)
	@-mkdir build 2> /dev/null
	$(GO) generate ./...
	$(GO) get ./...
	$(GO) build $(GOFLAGS) -o $@ $(GOCMDDIR)/$(notdir $@)

# Print the value of a variable
_printvar-go-%: ; @echo $($*)
