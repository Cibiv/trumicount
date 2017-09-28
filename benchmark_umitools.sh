#!/bin/bash

set -e
set -o pipefail

export PYTHONNOUSERSITE=1
INPUTS="ec.1.bam|20|y|100|1 \
        ec.2.bam|20|y|100|1 \
        dm.1.bam|20|u|5|2 \
        dm.2.bam|20|u|2|2"
#INPUTS="ut.small.bam|20|p|100|1"

# Setup python & logging
exec > >(tee benchmark_umitools.log) 2>&1
source ~/Installs/miniconda2/bin/activate

for rep in 1 2 3; do
	for input in $INPUTS; do
		input_split=(${input//|/ })
		bam=${input_split[0]}
		mapq=${input_split[1]}
		case "${input_split[2]}" in
			y)
				paired=1
			;;
			u)
				paired=0
			;;
		esac
		th=${input_split[3]}
		mol=${input_split[4]}

		if [ "$paired" == "1" ]; then
			echo "==== PYTHON 2.7 $bam PATCHED PAIRED MAPQ=$mapq THRESHOLD=$th MOLECULES=$mol ==============="
			./trueumis.R \
				--input-bam $bam --umi-sep='|' --umipair-sep=: --paired --combine-strand-umis \
				--mapping-quality $mapq --threshold $th --molecules $mol \
				--verbose
		fi

		echo "==== PYTHON 2.7 $bam PATCHED UNPAIRED MAPQ=$mapq THRESHOLD=$th MOLECULES=$mol ==============="
		./trueumis.R \
			--input-bam $bam --umi-sep='|' \
			--mapping-quality $mapq --threshold $th --molecules $mol \
			--verbose

		if [ "$paired" == "1" ]; then
			echo "==== PYTHON 2.7 $bam UNPATCHED PAIRED MAPQ=$mapq THRESHOLD=$th MOLECULES=$mol ==============="
			./trueumis.R \
				--input-bam $bam --umi-sep='|' --paired \
				--mapping-quality $mapq --threshold $th --molecules $mol \
				--verbose
		fi

		echo "==== PYTHON 2.7 $bam UNPATCHED UNPAIRED MAPQ=$mapq THRESHOLD=$th MOLECULES=$mol ==============="
		./trueumis.R \
			--input-bam $bam --umi-sep='|' \
			--mapping-quality $mapq --threshold $th --molecules $mol \
			--verbose

	done
done
