#!/bin/sh

TEST=`pwd`
TEST=`basename $TEST`

fail() {
	if [ -n "$1" ]; then
		echo "$1 FAILED" 1>&2
	fi
	echo
	echo "${TEST}: Failed"
	echo
	exit 1
}

make build || fail "Build"
for EXE in `make -s _printvar-go-GOTARGETS`; do
	if [ ! -x "build/${EXE}" ]; then
		fail "Build Go"
	fi
done
for FILE in `make -s _printvar-copy-COPYTARGETS`; do
	if [ ! -e "build/`basename ${FILE}`" ]; then
		fail "Build Copy"
	fi
done

make test || fail "Test"

make testcover
if [ ! -f coverage.html ]; then
	fail "Test Coverage"
fi

make clean
if [ -d build ]; then
	fail "Clean"
fi

echo
echo "${TEST}: Success"
echo
