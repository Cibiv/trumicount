#!/bin/bash
ORIGINAL_BAM=/project/fgpProjects/pcrmodel/dm.tsu.15c.1/ngm.sorted.bam

samtools view -H "$ORIGINAL_BAM" \
	| sed -n 's/^.*\tSN:\([^\t]*\)\t.*$/\1/p' \
	| head -n 1000 \
	> kv_1000g.lst

samtools view -h "$ORIGINAL_BAM" $(cat kv_1000g.lst) \
	| sed 's/^\([^\t]*\)|\([AGCTN]*\)\/1\t/\1:\2\t/' \
	| samtools view -s 0.5 -b \
	> kv_1000g.bam
