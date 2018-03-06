#!/bin/bash

# ******************************************************************************
# *** Test Runner **************************************************************
# ******************************************************************************
#
# Test cases are represented by a .cmd and a .expected file in testcases/
# The .cmd-file is run with bash (supplying options -o pipefail and -e), and
# should produce a .output file in the current directory. If the .cmd completed
# without error (i.e. has exit status 0), the .output file is compared with the
# .expected file, and the test passes if both are sufficiently similar.
#
# Before running the tests, a conda environment is prepared containing the
# packages listed in the testenv-OS-MACHINE.pkgs file for the current machine
# and operating system. Additionally, gwpcR is installed by downloading the
# version set in dependencies.sh from github, and running R CMD INSTALL.

# Stop on error
set -o pipefail
set -e

# Locate "test" directory, include depdenencies.sh
export TESTS="$( cd "$(dirname "$0")" ; pwd -P )"
source "$TESTS/dependencies.sh"

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
	if test "$WORKDIR" != "" && test "$KEEP_WORKDIR" == ""; then
		echo "=== Removing working directory $WORKDIR"
		rm -rf "$WORKDIR"
	fi
}
trap on_exit EXIT

# Setup conda test environment
echo "=== Creating and activating test environment in $WORKDIR/testenv"
conda create --no-default-packages --use-index-cache --yes -p "$WORKDIR/testenv" --file "$TESTS/$TESTENV_PKGS"
source activate "$WORKDIR/testenv"

# Ensure that R uses only packages from the test environment
export R_LIBS="$(Rscript -e 'cat(.Library)')"
export R_LIBS_USER="-"
echo "=== Using R libraries in $(Rscript -e "cat(paste(.libPaths(), collapse=', '))")"

# Install gwpcR. We don't use conda here to make it possible to use a new
# version of gwpcR before the bioconda infrastructure has built the packages
echo "=== Installing gwpcR"
get_archive GWPCR
echo "Installing $CACHE/$GWPCR_ARCHIVE"
R CMD INSTALL "$CACHE/$GWPCR_ARCHIVE"

# Run tests in $TESTCASES
total="$(ls "$TESTCASES"/*.cmd | wc -l | sed 's/[[:space:]]*//')"
started=0
ran=0
ok=0
echo "=== Will run $total tests in $TESTCASES"
for tc in "$TESTCASES"/*.cmd; do
	# Extract test case name
	tcn="$(basename "$tc")"
	tcn="${tcn//.cmd}"
	# Run test case
	started=$(($started+1))
	# gawk might not be strictly necessary here, but trumicount requires it anyway, so...
	logger="gawk -v tcn=\"$tcn\" '{print \"[\" tcn \"] \" \$0; fflush()}'"
	echo "=== [$tcn] RUNNING ($started/$total)"
	if $BASH -e -o pipefail "$tc" 2>&1 | eval $logger; then
		# Test completed, compare output to expected output
		ran=$((ran+1))
		if diff "$tcn.out" "$TESTCASES/$tcn.expected" >/dev/null; then
			# Output agrees
			ok=$((ok+1))
			echo "=== [$tcn] SUCCESS ($started/$total)"
		else
			# Output differs
			(diff -Nau "$tcn.out" "$TESTCASES/$tcn.expected" || true) | eval $logger
			echo "=== [$tcn] FAILED ($started/$total)"
		fi
	else
		# Test aborted
		echo "=== [$tcn] ABORTED ($started/$total)"
	fi
done

# Report results
if test "$ok" == "$total"; then
	echo "=== ALL TESTS SUCCEEDED ($total tests)"
	exit 0
else
	echo "=== SOME TESTS FAILED or ABORTED ($total tests, $ok succeeded, $ran finished, $((total-ran)) aborted)"
	exit 1
fi
