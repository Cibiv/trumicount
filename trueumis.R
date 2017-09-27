#!/software/R/R-3.2.1/bin/Rscript

doc <- '
Usage: trueumi.R ( --input-bam INBAM | --input-umitools-group-out GROUPSINTAB | --input-grouped-umis GROUPEDUMISINTAB ) [ --output-counts COUNTSTAB ] [ --output-grouped-umis GROUPEDUMISTAB ] [ --output-final-umis FINALUMISTAB ] [ --report REPORT ] [ --umitools UMITOOLS ] [ --umitools-option UMITOOLSOPT ... ] [ --umi-sep UMISEP] [ --umipair-sep UMIPAIRSEP ] [ --paired ] [ --mapping-quality MAPQ ] [ --combine-strand-umis ] [ --threshold THRESHOLD ] [ --molecules MOLECULES ] [ --cores CORES ] [ --verbose ]

Options:
--input-bam INBAM                      file to read input from (mapped reads)
--input-umitools-group-out GROUPSINTAB file to read input from (as produced by umi_tools group)
--input-grouped-umis GROUPEDUMISINTAB  file to read input from (previously produced by --output-grouped-umis)
--output-counts COUNTSTAB              file to write corrected per-gene counts and model parameters to
--output-grouped-umis GROUPEDUMISTAB   file to write grouped UMIs to (to be later used with --input-grouped-umis)
--output-final-umis FINALUMISTAB       file to write grouped, strand-combined and filtered UMIs to
--report REPORT                        file to write report (in PDF format) to
--umitools UMITOOLS                    path to umitools [Default: umi_tools]
--umitools-option UMITOOLSOPT          additional options to pass to "umitools group" (see umi_tools group --help)
--umi-sep UMISEP                       separator between read name and UMI (passed to umi_tools) [Default: :]
--umipair-sep UMIPAIRSEP               separator between UMI on 1st and 2nd read in combined UMI of mate pair [Default: -]
--paired                               assume BAM file contains paired reads (passed to umi_tools) [Default: TRUE]
--mapping-quality MAPQ                 minimal required mapping quality (passed to umi_tools) [Default: 20]
--combine-strand-umis                  combine UMIs belonging to the two strands of a fragment [Default: FALSE]
--threshold THRESHOLD                  remove UMIs with fewer than THRESHOLD reads [Default: 2]
--molecules MOLECULES                  number of copies (strands) before amplification [Default: 2]
--cores CORES                          number of CPU cores to use when fitting the gene-wise models [Default: 1]
--verbose                              enable verbose output
'
OPTS.INVALID <- list(
  `input-bam`=c('input-umitools-group-out', 'input-grouped-umis'),
  `input-umitools-group-out`=c('input-bam', 'input-grouped-umis'),
  `input-grouped-umis`=c('input-bam', 'input-umitools-group-out')
)

GZEXT <- "\\.(gz|gzip2)$"
BZ2EXT <- "\\.(bz2|bzip2)$"

# The AWK program to transfrom the output of "umitools group" into a table of grouped UMIs
# We (crudely) remove newlines and comments, since we pass the program as a command-line
# argument to awk
GROUPOUT2UMIS.AWK <- gsub("\\s*(#.*)?\\n\\s*", "", perl=TRUE, '
BEGIN {
  gidp=-1;  # Prev. group id
  numis=1;  # Distinct # of raw UMIs
  lp="";    # Prev. line
  umip="";  # Prev. raw UMI
  FS="\\t";
  print "gene" "\\t" "sample" "\\t" "pos" "\\t" "end" "\\t" "umi" "\\t" "rawumis" "\\t" "reads";
}
NR==1 {
  # Read colum names
  Iread_id=Icontig=Iposition=Iposition2=Igene=Iumi=Iumi_count=Ifinal_umi=Ifinal_umi_count=Iunique_id=-1;
  for (i=1;i<=NF;i++) {
    switch ($i) {
      case "read_id": Iread_id=i; break;
      case "contig": Icontig=i; break;
      case "position": Iposition=i; break;
      case "position2": Iposition2=i; break;
      case "gene": Igene=i; break;
      case "umi": Iumi=i; break;
      case "umi_count": Iumi_count=i; break;
      case "final_umi": Ifinal_umi=i; break;
      case "final_umi_count": Ifinal_umi_count=i; break;
      case "unique_id": Iunique_id=i; break;
    }
  }
}
NR>1 {
  # Store because $0 might be reset below
  l=$0;
  gid=$Iunique_id;
  umi=$Iumi;
  if (gidp==-1) {
    # First line, skip
  }
  else if (gid!=gidp) {
    # Group changed, output previous group
    $0=lp; # Switch back to (last line of) previous group
    print ($Igene=="NA"?$Icontig:$Igene) "\\t" "" "\\t" $Iposition "\\t" (Iposition2>0?$Iposition2:"NA") "\\t" $Ifinal_umi "\\t" numis "\\t" $Ifinal_umi_count;
    numis=1;
  }
  else if (umi!=umip) {
    # Raw UMI changed within group
    numis+=1;
  }
  # Remember prev. line, group id and UMI
  lp=l;
  gidp=gid;
  umip=umi
}
END {
  # Output last group
  $0=lp;
  print ($Igene=="NA"?$Icontig:$Igene) "\\t" "" "\\t" $Iposition "\\t" (Iposition2>0?$Iposition2:"NA") "\\t" $Ifinal_umi "\\t" numis "\\t" $Ifinal_umi_count;
}
')

open_byext <- function(path, ...) {
  if (grepl(GZEXT, path))
    gzfile(path, ...)
  else if (grepl(BZ2EXT, path))
    bzfile(path, ...)
  else
    file(path, ...)
}

# Parse arguments
ARGS <- docopt::docopt(doc, strip_names=TRUE)
ARGS$`mapping-quality` <- as.integer(ARGS$`mapping-quality`)
ARGS$threshold <- as.integer(ARGS$threshold)
ARGS$molecules <- as.integer(ARGS$molecules)
ARGS$cores <- as.integer(ARGS$cores)
if (ARGS$verbose)
  print(list(`Command Line Arguments`=ARGS))

# Create connection to read grouped UMI table from
umis_con <- if (!is.null(ARGS$`input-grouped-umis`)) {
  # Simple read grouped UMI table from file as-is
  if (sum(!sapply(ARGS[OPTS.INVALID$`input-grouped-umis`], is.null)) > 0)
    stop('--input-grouped-umis is incompatible with ', paste(OPTS.INVALID$`input-grouped-umis`, collapse=', '))

  # Table will be read from this file connection
  open_byext(ARGS$`input-grouped-umis`, open='r')
} else {
  # Grouped UMI table must be created
  cmds <- list()

  if (!is.null(ARGS$`input-bam`)) {
    # Input is BAM File, we use umi_tools to group similar UMIs. It outputs a line per read,
    # but indicates which reads belong to the same UMI group.
    cmds[[length(cmds)+1]] <- paste("/usr/bin/time", "-f", "'umi_tools resources: user: %U sec, kernel: %K sec, memory: %M kB'",
                                    shQuote(ARGS$`umitools`), 'group', '--group-out /dev/stdout',
                                    '-I', shQuote(ARGS$`input-bam`),
                                    '-L', ifelse(ARGS$verbose, '/dev/stderr', '/dev/null'),
                                    '--umi-sep', shQuote(ARGS$`umi-sep`),
                                    ifelse(ARGS$paired, '--paired', ''),
                                    '--mapping-quality', ARGS$`mapping-quality`,
                                    paste(shQuote(ARGS$`umitools-option`), collapse=' '), sep=' ')
  }
  else if (!is.null(ARGS$`input-umitools-group-out`)) {
    # Input is the raw 'umitools group' output. 
    if (sum(!sapply(ARGS[OPTS.INVALID$`input-umitools-group-out`], is.null)) > 0)
      stop('--input-umitools-group-out is incompatible with ', paste(OPTS.INVALID$`input-umitools-group-out`, collapse=', '))
    tool <- if (grepl(GZEXT, path)) 'zcat'
    else if (grepl(BZ2EXT, path)) 'bzcat'
    else 'cat'
    cmds[[length(cmds)+1]] <- paste(tool, shQuote(ARGS$`input-umitools-group-out`), sep=' ')
  }

  # Reduce 'umitools group' output to a single line per group. 
  cmds[[length(cmds)+1]] <- paste('awk', shQuote(GROUPOUT2UMIS.AWK), sep=' ')

  # If requested, save the grouped UMI table. The table can later be loaded directly
  # using --input-grouped-umis
  if (!is.null(ARGS$`output-grouped-umis`)) {
    # Materialize table, then read back
    tool <- if (grepl(GZEXT, ARGS$`output-grouped-umis`)) 'gzip --stdout'
    else if (grepl(BZ2EXT, ARGS$`output-grouped-umis`)) 'bzip2 --stdout'
    else 'cat'
    cmds[[length(cmds)+1]] <- paste(tool, '>', shQuote(ARGS$`output-grouped-umis`), sep=' ')
    message('*** Materializing table of grouped UMIs to ', ARGS$`output-grouped-umis`)
    if (ARGS$verbose)
      cat(paste0('Command: ', paste(cmds, collapse=" |\n         "), "\n"))
    system(paste(cmds, collapse=' | '))

    # Table will be read from the created file
    open_byext(ARGS$`output-grouped-umis`, open='r')
  } else {
    # Table will be read from this pipe
    message('*** Computing table of grouped UMIs on the fly')
    if (ARGS$verbose) {
      cat(paste0('Command: ', paste(cmds, collapse=" |\n         "), "\n"))
    }
    pipe(paste(cmds, collapse=' | '), open='r')
  }
}

# Read table using connection established above
library(data.table)
message('*** Reading list of grouped UMIs')
umis <- data.table(read.table(umis_con, header=TRUE, sep="\t",
                              colClasses=c(gene='factor', sample='factor',
                                           pos='numeric', end='numeric', umi='character',
                                           rawumis='numeric', 'reads'='numeric')))
message('Found ', nrow(umis), ' UMIs for ', length(levels(umis$gene)), ' genes in ',
        length(unique(umis$sample)), ' samples after grouping of similar UMIs')

# Filter UMIs
if (ARGS$threshold > 0) {
  message('*** Filtering UMIs with fewer than ', ARGS$threshold, ' reads')
  umis <- umis[reads >= ARGS$threshold]
}

# Combine UMIs
if (ARGS$`combine-strand-umis`) {
  message('*** Merging UMIs belonging to the two strands of a single template molecule')
  # In combine-strand mode, UMIs that correspond to the two strands of a single
  # template molecule are joined together (this requires Y-shaped adapter which
  # allow the PCR products of the two strands to be distinguished). Such pairs
  # are recognized by their "reciprocity" -- first and second read of the mate 
  # pair are swapped, INCLUDING the UMIs found on these reads. For each of these
  # UMIs, we keep only the one where the first read maps in forward direction,
  # and (arbitrarily?) call it the one mapping to the plus strand. We keep the
  # strand-specific read counts in two columns, reads.plus and reads.minus, and
  # set the overall read count to the sum of the two. When applying the threshold,
  # we filter based on the strand-specific counts, and require BOTH to be
  # sufficiencly large.
  umis.m <- umis[end < pos,
                 list(gene, sample, pos=end, end=pos,
                      umi=as.character(unlist(lapply(FUN=function(e) {paste(rev(e), collapse=ARGS$`umipair-sep`)},
                                                     strsplit(umi, ARGS$`umipair-sep`, fixed=TRUE)))),
                      reads=reads) ]
  umis <- umis[pos < end]
  umis[, reads.plus := reads ]
  umis[, reads.minus := umis.m[umis, reads, on=c("gene", "sample", "pos", "end", "umi")] ]
  umis <- umis[is.finite(reads.plus) & is.finite(reads.minus)]
  umis[, reads := reads.plus + reads.minus ]

  # Since the total read count is now the sum of the two strand's read counts,
  # the effective initial molecule size is doubled
  ARGS$molecules <- ARGS$molecules * 2
}

# Output final UMI table
if (!is.null(ARGS$`output-final-umis`))
  write.table(umis, file=open_byext(ARGS$`output-final-umis`, open='w'),
              col.names=TRUE, row.names=FALSE, sep="\t", quote=FALSE)

# Report final UMI count
message(nrow(umis), ' UMIs remained for ', length(levels(umis$gene)), ' genes in ',
        length(unique(umis$sample)), ' samples after removing UMIs with fewer than ',
        ARGS$threshold, ' reads', ifelse(ARGS$`combine-strand-umis`,
        ' and combining plus- and minus-strand UMIs', ''))
if (nrow(umis) < 2)
  stop("Too few UMIs to continue")

# Fit global model
message('*** Fitting global PCR and sequencing model')
library(gwpcR)
gm <- gwpcrpois.mom(mean(umis$reads, na.rm=TRUE), var(umis$reads, na.rm=TRUE),
                    threshold=ARGS$threshold, molecules=ARGS$molecules)
message('Overall efficiency ', round(100*gm$efficiency), '%, depth=', round(gm$lambda0, digits=3), ' reads/UMI')
