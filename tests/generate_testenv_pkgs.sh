#!/bin/bash

# ******************************************************************************
# *** Package List Generator ***************************************************
# ******************************************************************************
#
# Generates testenv-OS-MACHINE.pkgs

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
conda create --no-default-packages --yes -p "$WORKDIR/testenv"
source activate "$WORKDIR/testenv"
while read -r channel || [[ -n "$channel" ]]; do
	conda config --env --add channels "$channel"
done < "$TESTS/testenv.channels"
conda info

PKGS="$(cat "$TESTS/testenv.pkgs" | sed -n 's/^[[:space:]]*\([^[:space:]#]\{1,\}\)[[:space:]]*\(\['"$PKGSPECOS"'\]\)\{0,1\}$/\1/p' | xargs echo)"
echo "=== Will install $PKGS for OS $PKGSPECOS"
conda install --yes $PKGS

echo "=== Saving explicit package list to $TESTS/$TESTENV_PKGS"
conda list --explicit > "$TESTS/$TESTENV_PKGS"
