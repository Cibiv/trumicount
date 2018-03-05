$TRUMICOUNT --input-umitools-group-out $TESTCASES/kv_1000g.q20.gout.bz2 \
	--molecules 2 --threshold 2  --genewise-min-umis 3 \
	--output-counts kv_1000g.q20.tab
diff kv_1000g.q20.tab $TESTCASES/kv_1000g.q20.tab.expected >/dev/null
