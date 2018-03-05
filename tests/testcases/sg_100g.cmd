$TRUMICOUNT --input-umitools-group-out "$TESTCASES/sg_100g.q20.gout.bz2" \
	--paired --filter-strand-umis --umipair-sep '-' \
	--molecules 1 --threshold 24 \
	--output-counts sg_100g.q20.tab &&
diff sg_100g.q20.tab "$TESTCASES/sg_100g.q20.tab.expected" >/dev/null
