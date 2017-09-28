#!/bin/bash
dollarstar="$*"
n=$#
while [[ $n > 0 ]]; do
	shift
	n=$[$n-1]
done

export PYTHONNOUSERSITE=1

source ~/Installs/miniconda2/bin/activate

exec umi_tools $dollarstar
