# Common Make

This repo contains common Make recipes for use at ANet.  These recipes should be used
in preference to each repo repeating similar code in its Makefile.

Recipe categories currently include:

* Go
* Copy

## Go

Recipes for building, testing and checking Go executables are included in `go-common.mk`

### Targets

The primary targets provided for Go are:

* __build__ - Builds Go executables
* __clean__ - Removes build targets
* __lint__ - Lints Go source
* __test__ - Runs Go unit tests
* __testcover__ - Runs Go unit tests and produces code coverage data

Each primary target depends on three sub-targets, which use the prefixes `pre-`,
`standard-`, and `post-`.  E.g., the sub-targets for the `build` target are
`pre-build`, `standard-build`, and `post-build`.  The common recipes only define
actions for `standard-` sub-target.  The others are provided to allow custom actions.

### Variables

These variables are used by the standard targets and may be overridden:

* __PROJECT__ - The name of the project being built.  Defaults to the name of the current directory (which should be also the name of the repository)
* __BUILDDIR__ - The location that build artifacts will be placed in.  Defaults to `./build`
* __GOTARGETS__ - A list of the executables to build.  Defaults to the project name
* __GOCMDDIR__ - The location of the directory containing the sub-directories for the executables to be built.  Defaults to `./cmd`
* __GOROOTTARGET__ - Can be set to the name of a single target from `GOTARGETS` if the main executable code for it is in the top level directory.  No default
* __GOSRC__ - A list of the Go source files.  Defaults to all Go source files recursively found in the current directory
* __GO__ - The Go executable to run.  Defaults to `go`
* __GOFLAGS__ - Flags to pass to `go build`.  No default
* __GOTESTTARGET__ - The target to pass to `go test`.  Defaults to `./...`, which means all tests in the project
* __GOTESTFLAGS__ - Flags to pass to `go test`.  Defaults to `-v -race`


## Copy

Recipes for copying files as part of the build are included in `copy-common.mk`

### Targets

The primary targets provided for Go are:

* __build__ - Copies files into the build directory
* __clean__ - Removes build targets

Each primary target depends on three sub-targets, which use the prefixes `pre-`,
`standard-`, and `post-`.  E.g., the sub-targets for the `build` target are
`pre-build`, `standard-build`, and `post-build`.  The common recipes only define
actions for `standard-` sub-target.  The others are provided to allow custom actions.

### Variables

These variables are used by the standard targets and may be overridden:

* __PROJECT__ - The name of the project being built.  Defaults to the name of the current directory (which should be also the name of the repository)
* __BUILDDIR__ - The location that build artifacts will be placed in.  Defaults to `./build`
* __COPY__ - The program to use to copy files.  Defaults to `cp`
* __COPYTARGETS__ - A list of files and directories to be copied into `BUILDDIR`.  No default
* __COPYFLAGS__ - Flags to pass to `COPY`.  Defaults to `-r`

## Using

The normal way to use the common make recipes is to include the appropriate files in
the Makefile for a repository.  For a simple Go microservice, just including
`go-common.mk` may be all that is required in the Makefile, for example:

```make
include go-common.mk
```

### Include

In all cases the Makefile will ultimately reference one or more of the `*-common.mk`
files in this package, usually through the use of the `include` directive.  However,
there are a number of options on how this directive can be resolved.

#### Dynamic download

In this option, the Makefile includes a target for creating the common make file that
is included by downloading it from Github as well as an `include` directive.  In this
case the name of the common make file that is downloaded should be added to
`.gitignore` for the package so that it is not inadvertently committed.

`curl` will be used in the following examples to illustrate a variety of forms this
could take.

Get the most recent version of `go-common-mk`:

```make
include go-common.mk

go-common.mk:
	curl -O -L https://raw.github.com/AchievementNetwork/common-make/master/go-common.mk
```

Get the version for a specific release:

```make
include go-common.mk

go-common.mk:
	curl -O -L https://raw.github.com/AchievementNetwork/common-make/1.0.0/go-common.mk
```

Get the version for a specific commit:

```make
include go-common.mk

go-common.mk:
	curl -O -L https://raw.github.com/AchievementNetwork/common-make/<commit-hash>/go-common.mk
```

__Pros__

* New common make features will be pulled in automatically as they are added (although see the caveat in the __Cons__ section)
* Depending on the download recipe used, package maintainers have flexibility in whether they will automatically pick up none, some, or all updates

__Cons__

* All users, including the package builder, must have network access in order to build the package, at least initially
* Developers may need to periodically to refresh the common make files if another developer starts using the features of a newer version

#### Local copy

In this option, a copy of the appropriate `*-common.mk` file(s) are downloaded manually and
checked into the package being built.  In this case the Makefile can just use the
`include` directive with no additional complications.

__Pros__

* The Makefile only needs a simple include statement
* The package is self-contained and fully in control of pulling in future common make infrastructure updates

__Cons__

* Developers may make local changes to the common make infrastructure which are not fed upstream, making future updates painful or even infeasible in the worst cases
* The package will not pick up any common make updates without manual intervention


### Overriding variables

Overriding variables should be done before referencing the common make recipes.  E.g., to
override `GOFLAGS` so that package names are printed as they are compiled your
`Makefile` might look like

```make
GOFLAGS=-v

include go-common.mk
```

### Adding to targets

All public targets in the common make recipes are so-called double colon targets.  This
means that additional targets with the same name can be defined and they will be run in
addition to the common make targets.

These additional targets must also be double colon targets, since Make does not allow a
target to have both single and double colon versions.

As trivial example, to print a message that the main build step was about to start your
`Makefile` might look like this:

```make
pre-build::
	@echo "Main build about to start"

include go-common.mk
```

Note that the `pre-` and `post-` targets are all designed to specifically allow for
this and are empty in the common make infrastructure.

### Overriding targets

There may be instances where you want to use some targets from the common make recipes
but want to override others.  This requires a little more work, but can be done.

Before doing this, it is worth asking whether what you want to achieve should be
supported enhancement.  If so, please consider making such a change in preference from using
this technique.

To completely override the `build` target, for example, so that none of the common make
`build` target is run, but all of the other common make targets are available, your Makefile might look like this:

```make
build:
	go build ./...

%: force
	@$(MAKE) -f go-common.mk $@

force: ;

.PHONY: build force
```
