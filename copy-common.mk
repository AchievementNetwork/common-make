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
