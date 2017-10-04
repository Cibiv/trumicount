#!/bin/bash
ORIGINAL_BAM=/project/fgpProjects/pcrmodel/ec.1/ngm.sorted.bam

samtools view -H "$ORIGINAL_BAM" \
	| sed -n 's/^.*\tSN:\([^\t]*\)\t.*$/\1/p' \
	| head -n 100 \
	> sg_100g.lst

samtools view -h "$ORIGINAL_BAM" $(cat sg_100g.lst) \
	| sed 's/^\([^\t]*\)|\([AGCTN]*\):\([ACGTN]*\)\t\(.*\)$/\1:\2-\3\t\4/' \
	| samtools view -s 0.25 -b \
	> sg_100g.bam
