#!/bin/bash

set -e
set -o pipefail

export PYTHONNOUSERSITE=1
INPUTS="ec.1.bam|20|p|100|1 \
        ec.2.bam|20|p|100|1 \
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
                        p)
                                paired_opts="--combine-strand-umis"
                        ;;
                        u)
                                paired_opts=""
                        ;;
                esac
                th=${input_split[3]}
                mol=${input_split[4]}

                echo "==== PYTHON 2.7 $bam PATCHED PAIRED MAPQ=$mapq THRESHOLD=$th MOLECULES=$mol ==============="
                ./trueumis.R \
                        --input-bam $bam --umi-sep='|' --paired --umipair-sep=: \
                        --mapping-quality $mapq $paired_opts --threshold $th --molecules $mol \
                        --verbose

                echo "==== PYTHON 2.7 $bam PATCHED UNPAIRED MAPQ=$mapq THRESHOLD=$th MOLECULES=$mol ==============="
                ./trueumis.R \
                        --input-bam $bam --umi-sep='|' \
                        --mapping-quality $mapq --threshold $th --molecules $mol \
                        --verbose

                echo "==== PYTHON 2.7 $bam UNPATCHED PAIRED MAPQ=$mapq THRESHOLD=$th MOLECULES=$mol ==============="
                ./trueumis.R \
                        --input-bam $bam --umi-sep='|' --paired \
                        --mapping-quality $mapq --threshold $th --molecules $mol \
                        --verbose

                echo "==== PYTHON 2.7 $bam UNPATCHED UNPAIRED MAPQ=$mapq THRESHOLD=$th MOLECULES=$mol ==============="
                ./trueumis.R \
                        --input-bam $bam --umi-sep='|' \
                        --mapping-quality $mapq --threshold $th --molecules $mol \
                        --verbose

        done
done
