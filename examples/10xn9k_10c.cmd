trumicount --input-bam 10xn9k_10c.bam \
  --molecules 1 --threshold 2 --group-per cell,gene \
  --umitools-option --per-gene --umitools-option --gene-tag=XF \
  --output-plots 10xn9k_10c.pdf --output-counts 10xn9k_10c.tab
