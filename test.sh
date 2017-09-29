#!/bin/bash

set -o pipefail
set -e
export PYTHONNOUSERSITE=1

# Conda's activate doesn't like it if $* is non-empty
dollarstar="$*"
n=$#
while [[ $n > 0 ]]; do
	shift
	n=$[$n-1]
done

# Setup python & logging
exec > >(tee $log) 2>&1
source ~/Installs/miniconda2/bin/activate

for input_stem in $dollarstar; do
        input_stem=${input_stem//.bam}
	bam=${input_stem}.bam
	grouped_umis=${input_stem}.umis.tab.gz
	counts=${input_stem}.counts.tab.gz
	plot=${input_stem}.plot.pdf
	log=${input_stem}.log
	opts=${input_stem}.opts

	if [ -e "$grouped_umis" ]; then
		input_opts="--input-grouped-umis $grouped_umis"
	else
		input_opts="--input-bam $bam --output-grouped-umis $grouped_umis "
	fi

	./trueumis.R \
		$input_opts --output-counts $counts --output-plot $plot \
		--cores 4 $(cat $opts)
done
