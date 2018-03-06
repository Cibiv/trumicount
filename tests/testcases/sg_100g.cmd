$TRUMICOUNT --input-umitools-group-out "$TESTCASES/sg_100g.gout.bz2" \
	--paired --filter-strand-umis --umipair-sep '-' \
	--molecules 1 --threshold 24 \
	--output-counts sg_100g.out
