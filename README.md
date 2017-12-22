# Installation

The most convenient way of installing `TRUmiCount` is via the [https://conda.io]
(Conda) package manager. We're working on getting TRUmiCount added to the
[https://bioconda.github.io](BioConda) channel that allows many bioinformatcs
tools to be installed with a single command. For now, until that is done, you
need to add our custom Conda channel as a package source to install TRUmiCount.
After installing Conda and adding the BioConda channels, do the following

1. `conda config --env --add channels http://www.cibiv.at/~pflug_/conda/` to
   add our channel as a package source to conda.

2. `conda install TRUmiCount umi_tools`. (`umi_tools` are not a strict dependency
   of TRUmiCount, but necessary in many common use-cases)

See the manual for details on the installation & usage of `TRUmiCount`

# Manual

The manual for the latest version of TRUmiCount is available here
https://github.com/Cibiv/TRUmiCount/blob/latest-release/manual/manual.pdf

# Publications

The implemented model is described in detail in our paper *TRUmiCount: Correctly counting
absolute numbers of molecules using unique molecular identifiers*, Florian G. Pflug & Arndt
von Haeseler, Preprint at https://www.biorxiv.org/content/early/2017/11/13/217778. (2017).

# License

`TRUmiCount` is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

`TRUmiCount` is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
details.
