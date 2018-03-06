#!/bin/bash

# ******************************************************************************
# *** Conda Installer for the CI Systems ***************************************
# ******************************************************************************

# Stop on error
set -o pipefail
set -e

# Locate "test" directory, include depdenencies.sh
export TESTS="$( cd "$(dirname "$0")" ; pwd -P )"
source "$TESTS/dependencies.sh"

# Directory to install conda to
CONDADIR="$HOME/conda"

# Check if conda is already installed
if test -d "$CONDADIR" && \
   test -f "$CONDADIR/.version" && \
   test "$(cat $CONDADIR/.version)" == "$CONDA_VERSION"
then
	echo "=== Found conda installation in $CONDADIR, will use it"
	exit 0
elif test -d "$CONDADIR"; then
	echo "=== Incomplete conda installation in $CONDADIR, removing it"
	rm -rf "$CONDADIR"
fi

# Install conda
echo "=== Installing conda $CONDA_VERSION into $CONDADIR"
get_archive CONDA
$BASH "$CACHE/$CONDA_ARCHIVE" -b -p "$CONDADIR"
echo "$CONDA_VERSION" > $CONDADIR/.version
