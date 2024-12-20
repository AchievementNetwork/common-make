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
GODEBUG ?=
GOBUILDFLAGS ?=
GOBUILDENV ?=
GORUNGENERATE ?= yes
GOGENERATEENV ?=
GOTESTTARGET ?= ./...
GOTESTFLAGS ?= -race
GOTESTENV ?=
GOTESTCOVERRAW ?= coverage.raw
GOTESTCOVERHTML ?= coverage.html
GOLINTFLAGS ?= --timeout 5m
GOLINTERIMPORTPATH ?= github.com/golangci/golangci-lint/cmd/golangci-lint

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
endif # GOTARGETS
endif # GOROOTTARGET

ifdef GODEBUG
GOBUILDFLAGS += -gcflags "all=-N -l"
endif # GODEBUG

## Targets

.PHONY: build clean generate lint test testcover
.PHONY: pre-build standard-build post-build
.PHONY: pre-clean standard-clean post-clean
.PHONY: pre-generate standard-generate post-generate
.PHONY: pre-lint standard-lint post-lint
.PHONY: pre-test standard-test post-test
.PHONY: pre-testcover standard-testcover post-testcover
.PHONY: _checkcommonupdate _commonupdate

## External targets
# These may be overridden and used in repo Makefiles

# Build all targets
build:: pre-build standard-build post-build

pre-build::

standard-build:: $(_GO_ROOT_BUILD_TARGET) $(_GO_BUILD_TARGETS) generate
ifdef GOLIBRARYTARGET
	$(GOBUILDENV) $(GO) build $(GOBUILDFLAGS) $(GOLIBRARYTARGET)
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

# Generate code
generate:: pre-generate standard-generate post-generate

pre-generate::

standard-generate::
ifdef GORUNGENERATE
	$(GOGENERATEENV) $(GO) generate ./...
endif # GORUNGENERATE

post-generate::

# Lint code
lint:: pre-lint standard-lint post-lint

pre-lint::

standard-lint:: generate
	$(GO) mod why $(GOLINTERIMPORTPATH) 2> /dev/null | \
		tail -1 | grep '^$(GOLINTERIMPORTPATH)$$' 2>&1 > /dev/null || \
		( if [ -f tools.go ]; then \
			eval "$$_common_make_tools_lint_help"; \
		  else \
			eval "$$_common_make_no_tools_lint_help"; \
		  fi; \
		  exit 1 )
	$(GO) run github.com/golangci/golangci-lint/cmd/golangci-lint run $(GOLINTFLAGS)

post-lint::

# Run unit tests
test:: pre-test standard-test post-test

pre-test::

standard-test:: generate
	$(GOTESTENV) $(GO) test $(GOTESTFLAGS) $(GOTESTTARGET)

post-test::

testcover:: pre-testcover standard-testcover post-testcover

pre-testcover::

standard-testcover:: generate $(GOTESTCOVERHTML)

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
$(GOTESTCOVERRAW): $(GOSRC)
	$(GOTESTENV) $(GO) test $(GOTESTFLAGS) -coverprofile=cover.out.tmp $(GOTESTTARGET)
	grep -v "fake_" cover.out.tmp > $@
	rm cover.out.tmp

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
$(_GO_ROOT_BUILD_TARGET): $(GOSRC) generate
	@-mkdir build 2> /dev/null
	$(GOBUILDENV) $(GO) build $(GOBUILDFLAGS) -o $@ .

$(_GO_BUILD_TARGETS): $(GOSRC) generate
	@-mkdir $(BUILDDIR) 2> /dev/null
	$(GOBUILDENV) $(GO) build $(GOBUILDFLAGS) -o $@ $(GOCMDDIR)/$(notdir $@)


# Print the value of a variable
_printvar-go-%: ; @echo $($*)

# Lint-related messages
define __common_make_no_tools_lint_help
cat <<EOF
No dependency on golangci-lint found!

Please create a top level tools.go file with contents like

-
//go:build tools
// +build tools

package tools

import _ "github.com/golangci/golangci-lint/cmd/golangci-lint"
-

(the package may need adjusting) and then run 'go mod tidy'.

Then commit the new file and changes to 'go.mod' and 'go.sum'.
EOF
endef
export _common_make_no_tools_lint_help = $(value __common_make_no_tools_lint_help)

define __common_make_tools_lint_help
cat <<EOF
No dependency on golangci-lint found!

Please add an import of "github.com/golangci/golangci-lint/cmd/golangci-lint"
to the tools.go file and then run 'go mod tidy'.

Then commit the changes to the file and changes to 'go.mod' and 'go.sum'.
EOF
endef
export _common_make_tools_lint_help = $(value __common_make_tools_lint_help)
