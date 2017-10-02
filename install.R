#!/usr/bin/env Rscript

doc <- '
Usage: install [ --install-program INSTALL ] [ --prefix PREFIX ]

Options:
--install-program INSTALL    `install` program to use [Default: install]
--prefix PREFIX              Installation prefix [Default: /usr]
'
ARGS <- docopt::docopt(doc, strip_names=TRUE)

system(paste(ARGS$`install-program`, "trumicount", paste0(ARGS$prefix, "/bin/"), sep=" "))
