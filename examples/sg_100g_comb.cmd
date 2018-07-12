trumicount --input-bam sg_100g.bam --umi-sep ':' --umipair-sep '-' \
  --paired --combine-strand-umis --molecules 1 --threshold 24 \
  --output-plots sg_100g_comb.pdf --plot-hist-bin 3 \
  --output-counts sg_100g_comb.tab
