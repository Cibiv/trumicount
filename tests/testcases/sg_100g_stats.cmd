$TRUMICOUNT --input-umitools-group-out "$TESTCASES/sg_100g.gout.bz2" \
	--paired --filter-strand-umis --umipair-sep '-' \
	--molecules 1 --threshold 24 \
	--include-filter-statistics \
	--output-counts sg_100g_stats.output --digits 2
