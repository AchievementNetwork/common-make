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

# Standard variables for copied files
COPY ?= cp
COPYTARGETS ?=
COPYFLAGS ?= -r

# Default output directory for executables and associated (copied) files
BUILDDIR ?= build

ifdef COPYTARGETS
_COPY_BUILD_TARGETS := $(addprefix $(BUILDDIR)/,$(notdir $(COPYTARGETS)))
else
_COPY_BUILD_TARGETS :=
endif

## Targets

.PHONY: build clean
.PHONY: pre-build standard-build post-build
.PHONY: pre-clean standard-clean post-clean
.PHONY: _checkcommonupdate _commonupdate

## External targets
# These may be overridden and used in repo Makefiles

# Build all targets
build:: pre-build standard-build post-build

pre-build::

standard-build:: $(_COPY_BUILD_TARGETS)

post-build::

# Clean up build artifacts
clean:: pre-clean standard-clean post-clean

pre-clean::

standard-clean::
ifdef _COPY_BUILD_TARGETS
	-$(RM) $(_COPY_BUILD_TARGETS)
endif
	-rmdir $(BUILDDIR)

post-clean::

# External targets that can be used, but should not be overridden

_checkcommonupdate::
	@TMP_FILE=`mktemp copy-common.mk.XXXXXX`; \
		curl -o $${TMP_FILE} -s -S -L https://raw.github.com/AchievementNetwork/common-make/main/copy-common.mk; \
		if [ $$? -ne 0 ]; then echo "Update check failed"; exit 1; fi; \
		diff -b --brief copy-common.mk $${TMP_FILE} > /dev/null; \
		if [ $$? -ne 0 ]; then echo "It looks like copy-common.mk is out of date.  Please run \`make _commonupdate\`"; else echo "copy-common.mk up to date"; fi; \
		$(RM) $${TMP_FILE}

_commonupdate::
	@TMP_FILE=`mktemp copy-common.mk.XXXXXX`; \
		curl -o $${TMP_FILE} -s -S -L https://raw.github.com/AchievementNetwork/common-make/main/copy-common.mk; \
		if [ $$? -ne 0 ]; then echo "Update failed"; exit 1; fi; \
		mv $${TMP_FILE} copy-common.mk; \
		echo "Please test and then commit the new version of copy-common.mk"

## Internal targets
# DO NOT OVERRIDE OR USE
# Overriding may yield undefined results
# Names may change at any time

# Copy files
ifdef _COPY_BUILD_TARGETS
$(_COPY_BUILD_TARGETS): $(COPYTARGETS)
	$(COPY) $(COPYFLAGS) $(COPYTARGETS) $(BUILDDIR)/
endif

# Print the value of a variable
_printvar-copy-%: ; @echo $($*)
