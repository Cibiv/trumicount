#!/bin/bash
# ******************************************************************************
# *** Test Runner **************************************************************
# ******************************************************************************

# The .cmd-file is run with bash (supplying options -o pipefail and -e), and
# should produce a .output file in the current directory. If the .cmd completed
# without error (i.e. has exit status 0), the .output file is compared with the
# .expected file, and the test passes if both are sufficiently similar.

# Stop on error
set -o pipefail
set -e

# Expant '*' to nothing if nothing matches, instead of to a literal '*'
shopt -s nullglob

# Locate "test" directory, include depdenencies.sh
export EXAMPLES="$(readlink -f "$(dirname "$BASH_SOURCE")")"

# Determine which .cmd files to run
args=("$@")
commands=()
for arg in "${args[@]}"; do
	if [[ -f "$arg" ]]; then
		commands+=("$arg")
	elif [[ -f "$EXAMPLES/$arg.cmd" ]]; then
		commands+=("$EXAMPLES/$arg.cmd")
	else
		echo "Example '$arg' could not be located" >&2
		eixt 1
	fi
done
if [[ "${#commands[@]}" == "0" ]]; then
	commands=("$EXAMPLES"/*.cmd)
fi

# Run examples
total=${#commands[@]}
started=0
ran=0
ok=0
echo "=== Will run $total examples"
for tc in "${commands[@]}"; do
	# Extract test case name
	tcn="$(basename "$tc")"
	tcn="${tcn//.cmd}"
	# Run test case
	started=$(($started+1))
	# gawk might not be strictly necessary here, but trumicount requires it anyway, so...
	logger="gawk -v tcn=\"$tcn\" '{print \"[\" tcn \"] \" \$0; fflush()}'"
	echo "=== [$tcn] RUNNING ($started/$total)"
	if $BASH -e -o pipefail "$tc" 2>&1 | eval $logger; then
		# Example ran without error
		ran=$((ran+1))
	else
		# Example aborted
		echo "=== [$tcn] ABORTED ($started/$total)"
	fi
done

# Report results
if test "$ran" == "$total"; then
	echo "=== ALL EXAMPLES FINISHED SUCCESSFULLY ($total examples)"
	exit 0
else
	echo "=== SOME EXAMPLES ABORTED ($total examples, $ran finished, $((total-ran)) aborted)"
	exit 1
fi
