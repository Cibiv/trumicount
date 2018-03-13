[![Build Status](https://travis-ci.org/Cibiv/trumicount.svg?branch=master)](https://travis-ci.org/Cibiv/trumicount)
[![Install with Conda](https://anaconda.org/bioconda/trumicount/badges/installer/conda.svg)](https://anaconda.org/bioconda/trumicount)

# Description

*Motivation:*
Counting molecules using <i>next-generation sequencing</i> (NGS) suffers from
PCR amplification bias, which reduces the accuracy of many quantitative
NGS-based experimental methods such as RNA-Seq. This is true even if molecules
are made distinguishable using <i>unique molecular identifiers</i> (UMIs) before
PCR amplification, and distinct UMIs are counted instead of reads: Molecules
that are lost entirely during the sequencing process will still cause
under-estimation of the molecule count, and amplification artifacts like PCR
chimeras create phantom UMIs and thus cause over-estimation.<br>

*Results:* TRUmiCount uses a mechanistic model of PCR amplification to correct
for both types of errors. In our paper (see below) we demonstrate that the
phantom-filtered and loss-corrected molecule counts computed by TRUmiCount
measure the true number of molecules with considerably higher accuracy than the
raw number of distinct UMIs.<br>

# Availability

TRUmiCount is available on the [Bioconda](https://bioconda.github.io)
channel of the [Conda](https://conda.io) package manager.

```
conda install -c bioconda trumicount
```

# More Information

See https://cibiv.github.io/trumicount for detailes on the installation &
usage of TRUmiCount.

The TRUmiCount algorithmus and our model of PCR amplification and sequencing
is described in details in our paper *TRUmiCount: Correctly counting absolute
numbers of molecules using unique molecular identifiers*, Florian G. Pflug &
Arndt von Haeseler (2017), Preprint on [bioRxiv](https://www.biorxiv.org/content/early/2017/11/13/217778).

# License

`TRUmiCount` is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

`TRUmiCount` is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
details.
