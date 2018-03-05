#!/bin/bash

# Version of gwpcR to use
GWPCR_VERSION=0.9.9
GWPCR_ARCHIVE="v$GWPCR_VERSION.zip"
GWPCR_URL="https://github.com/Cibiv/gwpcR/archive/$GWPCR_ARCHIVE"

# Stop on error
set -o pipefail
set -e

# Find absolute path to "test" (i.e. script) directory
export TESTS="$( cd "$(dirname "$0")" ; pwd -P )"
export TESTCASES="$TESTS/testcases"
export TRUMICOUNT="$TESTS/../trumicount"

# Create temporary working directory, make it the cwd
WORKDIR="$(mktemp -d)"
if ! test -d "$WORKDIR"; then
	WORKDIR=""
	echo "Failed to create temporary working directory ($WORKDIR is not a directory):" >&2
	exit 1
fi
pushd "$WORKDIR" >/dev/null
echo "=== Created working directory $WORKDIR"

# Cleanup on exit
function on_exit() {
  popd >/dev/null
  if test "$ENVDIR" != ""; then
  	echo "=== Removing test environment $ENVDIR"
  	rm -rf "$ENVDIR"
  fi
  if test "$WORKDIR" != ""; then
  	echo "=== Removing working directory $WORKDIR"
  	rm -rf "$WORKDIR"
  fi
}
trap on_exit EXIT

# Create temporary directory to hold a temporary conda environment used to run the tests
ENVDIR="$(mktemp -d)"
if ! test -d "$ENVDIR"; then
	ENVDIR=""
	echo "Failed to create temporary directory to hold the test environment ($ENVDIR is not a directory):" >&2
	exit 1
fi
echo "=== Creating and activating test environment in $ENVDIR"
conda create --no-default-packages --use-index-cache --yes -p "$ENVDIR" --file "$TESTS/testenv.pkgs"
source activate "$ENVDIR" 

# Ensure that R uses only packages from the test environment
export R_LIBS="$(Rscript -e 'cat(.Library)')"
export R_LIBS_USER="-"
echo "=== Using R libraries in $(Rscript -e "cat(paste(.libPaths(), collapse=', '))")"

# Install gwpcR. We don't use conda here to make it possible to use a new
# version of gwpcR before the bioconda infrastructure has built the packages
echo "=== Installing gwpcR"
curl --progress-bar -O -L "$GWPCR_URL"
unzip -q -n "$GWPCR_ARCHIVE"
R CMD INSTALL "gwpcR-$GWPCR_VERSION"

# Run tests in $TESTCASES
total="$(ls "$TESTCASES"/*.cmd | wc -l)"
ran=0
ok=0
echo "=== Will run $total tests in $TESTCASES"
for tc in "$TESTCASES"/*.cmd; do
	# Extract test case name
	tcn="$(basename "$tc")"
	tcn="${tcn//.cmd}"
	# Run test case & report outcome
	ran=$(($ran+1))
	echo "=== [$tcn] RUNNING ($ran/$total)"
	if $BASH -e -o pipefail "$tc" 2>&1 | awk -v tcn="$tcn" '{print "[" tcn "] " $0}'; then
		ok=$(($ok+1))
		echo "=== [$tcn] SUCCESS ($ran/$total)"
	else
		echo "=== [$tcn] FAILURE ($ran/$total)"
	fi
done

# Report results
if test "$ok" == "$total"; then
	echo "=== ALL TESTS PASSED ($total tests)"
	exit 0
else
	echo "=== SOME TESTS FAILED ($ok tests out of $total tests succeeded)"
	exit 1
fi
