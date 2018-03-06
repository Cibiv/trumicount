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

# Locate "test" directory, include depdenencies.sh
export TESTCASES="$(cd "$(dirname "$BASH_SOURCE")" ; pwd -P )/testcases"

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
