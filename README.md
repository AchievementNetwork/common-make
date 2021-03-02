# Common Make

This repo contains common Make recipes for use at ANet.  These
recipes should be used in preference to each repo repeating similar
code in its Makefile.

Recipe categories currently include:

* Go
* Copy

## Go

Recipes for building, testing and checking Go executables are
included in `go-common.mk`

### Targets

The primary targets provided for Go are:

* __build__ - Builds Go executables
* __clean__ - Removes build targets
* __lint__ - Lints Go source
* __test__ - Runs Go unit tests
* __testcover__ - Runs Go unit tests and produces code coverage data

Each primary target depends on three sub-targets, which use the
prefixes `pre-`, `standard-`, and `post-`.  E.g., the sub-targets
for the `build` target are `pre-build`, `standard-build`, and
`post-build`.  The common recipes only define actions for `standard-`
sub-target.  The others are provided to allow custom actions.

### Variables

These variables are used by the standard targets and may be overridden:

* __PROJECT__ - The name of the project being built.  Defaults to the name of the repository or the current directory (if there is no git repository)
* __BUILDDIR__ - The location that build artifacts will be placed in.  Defaults to `./build`
* __GOTARGETS__ - A list of the executables to build.  Defaults to the project name
* __GOCMDDIR__ - The location of the directory containing the sub-directories for the executables to be built.  Defaults to `./cmd`
* __GOROOTTARGET__ - Can be set to the name of a single target from `GOTARGETS` if the main executable code for it is in the top level directory.  No default
* __GOLIBRARYTARGET__ - A target to pass to `go build` when an executable shouldn't be produced.  It would typically be set to `./...` in that situation.  No default
* __GOSRC__ - A list of the Go source files.  Defaults to all Go source files recursively found in the current directory
* __GO__ - The Go executable to run.  Defaults to `go`
* __GOFLAGS__ - Flags to pass to `go build`.  No default
* __GORUNGET__ - Run `go get` prior to building if defined.  Defaults to defined
* __GORUNGENERATE__ - Run `go generate` prior to building if defined.  Defaults to defined
* __GOTESTTARGET__ - The target to pass to `go test`.  Defaults to `./...`, which means all tests in the project
* __GOTESTFLAGS__ - Flags to pass to `go test`.  Defaults to `-v -race`
* __GOTESTCOVERRAW__ - File to write raw test coverage data to.  Defaults to `coverage.raw`
* __GOTESTCOVERHTML__ - File to write HTML formatted test coverage data to.  Defaults to `coverage.html`


## Copy

Recipes for copying files as part of the build are included in
`copy-common.mk`

### Targets

The primary targets provided for Go are:

* __build__ - Copies files into the build directory
* __clean__ - Removes build targets

Each primary target depends on three sub-targets, which use the
prefixes `pre-`, `standard-`, and `post-`.  E.g., the sub-targets
for the `build` target are `pre-build`, `standard-build`, and
`post-build`.  The common recipes only define actions for `standard-`
sub-target.  The others are provided to allow custom actions.

### Variables

These variables are used by the standard targets and may be overridden:

* __PROJECT__ - The name of the project being built.  Defaults to the name of the current directory (which should be also the name of the repository)
* __BUILDDIR__ - The location that build artifacts will be placed in.  Defaults to `./build`
* __COPY__ - The program to use to copy files.  Defaults to `cp`
* __COPYTARGETS__ - A list of files and directories to be copied into `BUILDDIR`.  No default
* __COPYFLAGS__ - Flags to pass to `COPY`.  Defaults to `-r`

## Using

The normal way to use the common make recipes is to include the
appropriate files in the Makefile for a repository.  For a simple
Go microservice, just including `go-common.mk` may be all that is
required in the Makefile, for example:

```make
include go-common.mk
```

### Include

In all cases the Makefile will ultimately reference one or more of
the `*-common.mk` files in this package, usually through the use
of the `include` directive.  While the include directive itself is
simple, it is worth mentioning how to obtain the file being included.

While it is possible to have a Make recipe that defines how to
create the file being included, the recommendation is that a copy
of the file be downloaded manually and checked in as part of setting
up the repository.  The benefits of this include:

* Simple set up for developers (cloning the repository is all they need to do)
* Consistent behaviour across a development team (all developers are working with the same copy of the common make infrastructure in a given repository)
* Repositories are fully self-contained
* The maintainers of the repository are in control of common make updates

A copy of the common make file infrastructure can be downloaded in
a variety of ways, including the use of the GitHub Web UI, or the
use of a command line tool such as `curl`, e.g.

```
curl -O -L https://raw.github.com/AchievementNetwork/common-make/main/go-common.mk
```

The downloaded `go-common.mk` (or whatever common make file is being
used) should then be added to the local repository with the relevant
VCS.

**The checked in file should not be modified locally, as this will make managing updates more complex**

#### Updating

To check if there are common make file updates run

```
make _checkcommonupdate
```

If updates are required, then run

```
make _commonupdate
```

The build should be tested locally before the updated files are committed

### Overriding variables

Overriding variables should be done before referencing the common
make recipes.  E.g., to override `GOFLAGS` so that package names
are printed as they are compiled your `Makefile` might look like

```make
GOFLAGS=-v

include go-common.mk
```

### Adding to targets

All public targets in the common make recipes are so-called double
colon targets.  This means that additional targets with the same
name can be defined and they will be run in addition to the common
make targets.

These additional targets must also be double colon targets, since
Make does not allow a target to have both single and double colon
versions.

As trivial example, to print a message that the main build step was
about to start your `Makefile` might look like this:

```make
pre-build::
	@echo "Main build about to start"

include go-common.mk
```

Note that the `pre-` and `post-` targets are all designed to
specifically allow for this and are empty in the common make
infrastructure.

### Overriding targets

There may be instances where you want to use some targets from the
common make recipes but want to override others.  This requires a
little more work, but can be done.

Before doing this, it is worth asking whether what you want to
achieve should be supported enhancement.  If so, please consider
making such a change in preference from using this technique.

To completely override the `build` target, for example, so that
none of the common make `build` target is run, but all of the other
common make targets are available, your Makefile might look like
this:

```make
build:
	go build ./...

%: force
	@$(MAKE) -f go-common.mk $@

force: ;

.PHONY: build force
```

## Access

The source code for this infrastructure is public to simplify
downloads and features like the ability to self-update.  It is not
expected to be used outside of the Achievement Networking engineering
team though, and may become private in the future.
