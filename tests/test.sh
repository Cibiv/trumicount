#!/bin/bash

GWPCR_RELEASE=latest-release

set -o pipefail
set -e

ENVDIR=$(mktemp -d)
trap "rm -rf \"$ENVDIR\"" EXIT
if ! test -d "$ENVDIR"; then
	echo "Failed to create temporary directory ($ENVDIR is not a directory):" >&2
	exit 1
fi

echo "=== Creating and activating test environment in $ENVDIR"
conda create --no-default-packages --use-index-cache --yes -p "$ENVDIR" --file testenv.pkgs
source activate "$ENVDIR" 

echo "=== Installing gwpcR"
curl -O -L https://github.com/Cibiv/gwpcR/archive/$GWPCR_RELEASE.zip
unzip -n $GWPCR_RELEASE.zip
R CMD INSTALL gwpcR-$GWPCR_RELEASE

result=0

echo "=== Running TRUmiCount on kv_1000g.q20.gout.bz2"
if 	../trumicount --input-umitools-group-out kv_1000g.q20.gout.bz2 \
		--molecules 2 --threshold 2  --genewise-min-umis 3 \
		--output-counts kv_1000g.tab && \
	diff kv_1000g.tab kv_1000g.tab.expected >/dev/null
then
	echo "=== SUCCESS"
else
	echo "=== FAILURE"
	result=1
fi

if	../trumicount --input-umitools-group-out sg_100g.q20.gout.bz2 \
		--paired --filter-strand-umis --umipair-sep '-' \
		--molecules 1 --threshold 24 \
		--output-counts sg_100g.tab &&
	diff sg_100g.tab sg_100g.tab.expected >/dev/null
then
	echo "=== SUCCESS"
else
	echo "=== FAILURE"
	result=1
fi

if test "$result" == "0"; then
	echo "=== ALL PASSED"
else
	echo "=== SOME TESTS FAILED"
fi

exit $result
