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
PROJECT_REPO_URL := $(shell git config --get remote.origin.url 2> /dev/null)
ifdef PROJECT_REPO_URL
PROJECT ?= $(shell basename -s .git $(PROJECT_REPO_URL))
else
PROJECT ?= $(shell basename $(CURDIR))
endif

# Standard go variables
GOTARGETS ?= $(PROJECT)
GOCMDDIR ?= ./cmd
GOROOTTARGET ?=
GOLIBRARYTARGET ?=
GOSRC ?= $(shell find . -name '*.go')
GO ?= go
GOFLAGS ?=
GORUNGENERATE ?= yes
GORUNGET ?= yes
GOTESTTARGET ?= ./...
GOTESTFLAGS ?= -v -race
GOTESTCOVERRAW ?= coverage.raw
GOTESTCOVERHTML ?= coverage.html

# Default output directory for executables and associated (copied) files
BUILDDIR ?= build

## Internal variables
# DO NOT OVERRIDE
ifdef GOROOTTARGET
_GO_BUILD_TARGETS := $(addprefix $(BUILDDIR)/,$(filter-out $(GOROOTTARGET),$(GOTARGETS)))
_GO_ROOT_BUILD_TARGET := $(addprefix $(BUILDDIR)/,$(GOROOTTARGET))
else
ifdef GOTARGETS
_GO_BUILD_TARGETS := $(addprefix $(BUILDDIR)/,$(GOTARGETS))
_GO_ROOT_BUILD_TARGET :=
else
_GO_BUILD_TARGETS :=
_GO_ROOT_BUILD_TARGET :=
endif
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
ifdef GOLIBRARYTARGET
ifdef GORUNGENERATE
	$(GO) generate ./...
endif # GORUNGENERATE
ifdef GORUNGET
	$(GO) get ./...
endif # GORUNGET
	$(GO) build $(GOFLAGS) $(GOLIBRARYTARGET)
endif

post-build::

# Clean up build artifacts
clean:: pre-clean standard-clean post-clean

pre-clean::

standard-clean::
ifdef _GO_BUILD_TARGETS
	-$(RM) $(_GO_BUILD_TARGETS)
endif
ifdef _GO_ROOT_BUILD_TARGET
	-$(RM) $(_GO_ROOT_BUILD_TARGET)
endif
	-$(RM) $(GOTESTCOVERRAW) $(GOTESTCOVERHTML)
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
ifdef GORUNGET
	$(GO) get -t ./...
endif # GORUNGET
	$(GO) test $(GOTESTFLAGS) $(GOTESTTARGET)

post-test::

testcover:: pre-testcover standard-testcover post-testcover

pre-testcover::

standard-testcover:: $(GOTESTCOVERHTML)

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
$(GOTESTCOVERRAW):
ifdef GORUNGET
	$(GO) get -t ./...
endif # GORUNGET
	$(GO) test $(GOTESTFLAGS) -coverprofile=$@ $(GOTESTTARGET)

$(GOTESTCOVERHTML): $(GOTESTCOVERRAW)
	$(GO) tool cover -html=$< -o $@
	@# To allow Code Climate to understand our uploaded coverage files
	@case "$$(grep '^module' go.mod | awk -F/ '{print$$NF}')" in \
		v[0-9]) \
			sed -i.versioned -e 's!/v[0-9]/!/!' "$(GOTESTCOVERRAW)" "$(GOTESTCOVERHTML)" && \
			rm -f "$(GOTESTCOVERRAW).versioned" "$(GOTESTCOVERHTML).versioned" \
			;; \
	esac

# Go executables
$(_GO_ROOT_BUILD_TARGET): $(GOSRC)
	@-mkdir build 2> /dev/null
ifdef GORUNGENERATE
	$(GO) generate ./...
endif # GORUNGENERATE
ifdef GORUNGET
	$(GO) get ./...
endif # GORUNGET
	$(GO) build $(GOFLAGS) -o $@ .

$(_GO_BUILD_TARGETS): $(GOSRC)
	@-mkdir $(BUILDDIR) 2> /dev/null
ifdef GORUNGENERATE
	$(GO) generate ./...
endif # GORUNGENERATE
ifdef GORUNGET
	$(GO) get ./...
endif # GORUNGET
	$(GO) build $(GOFLAGS) -o $@ $(GOCMDDIR)/$(notdir $@)

# Print the value of a variable
_printvar-go-%: ; @echo $($*)
