trumicount --input-bam kv_1000g.bam --umi-sep ':' \
  --molecules 2 --threshold 2  --genewise-min-umis 3 \
  --output-plots kv_1000g.pdf --plot-hist-bin 1 \
  --plot-var-bins 20 --plot-var-logy \
  --output-counts kv_1000g.tab \
  --cores 4
