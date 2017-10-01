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
	bam=tests/${input_stem}.bam
	grouped_umis=tests/${input_stem}.umis.tab.gz
	counts=tests/${input_stem}.counts.tab.gz
	plot=tests/${input_stem}.plot.pdf
	genewise=tests/${input_stem}.genewise.tab.gz
	log=tests/${input_stem}.log
	opts=tests/${input_stem}.opts

	if [ -e "$grouped_umis" ]; then
		input_opts="--input-grouped-umis $grouped_umis"
	else
		input_opts="--input-bam $bam --output-grouped-umis $grouped_umis "
	fi

	./trumicount \
		$input_opts --output-counts $counts --output-plot $plot \
		--output-genewise-fits $genewise --cores 4 $(cat $opts)
done
