#!/bin/bash

set -e
set -o pipefail

export PYTHONNOUSERSITE=1
export INBAM=ec.1.bam
#export INBAM=ut.small.bam

exec > >(tee benchmark_umitools.log) 2>&1

source ~/Installs/miniconda2/bin/activate
echo "********************************************************************************"
echo "==== PYTHON 2.7 EC.1 PATCHED PAIRED ============================================"
echo "********************************************************************************"
./trueumis.R \
	--input-bam $INBAM --umi-sep='|' --paired --umipair-sep=: \
	--mapping-quality 20 --combine-strand-umis --threshold 100 --molecules 2 \
	--verbose

source ~/Installs/miniconda2/bin/activate
echo "********************************************************************************"
echo "==== PYTHON 2.7 EC.1 PATCHED UNPAIRED =========================================="
echo "********************************************************************************"
./trueumis.R \
	--input-bam $INBAM --umi-sep='|' \
	--mapping-quality 20 --threshold 50 --molecules 1 \
	--verbose

source ~/Installs/miniconda2/bin/activate py27_orig
echo "********************************************************************************"
echo "==== PYTHON 2.7 EC1. UNPATCHED PAIRED =========================================="
echo "********************************************************************************"
./trueumis.R \
	--input-bam $INBAM --umi-sep='|' --paired \
	--mapping-quality 20 --threshold 50 --molecules 1 \
	--verbose

source ~/Installs/miniconda2/bin/activate py27_orig
echo "********************************************************************************"
echo "==== PYTHON 2.7 EC.1 UNPATCHED UNPAIRED ========================================"
echo "********************************************************************************"
./trueumis.R \
	--input-bam $INBAM --umi-sep='|' \
	--mapping-quality 20 --threshold 50 --molecules 1 \
	--verbose
