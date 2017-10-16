#!/bin/bash

set -e
set -o pipefail

ver=$1
if [ "$ver" == "" ]; then
	echo "Usage: $0 version" >&2
	exit 1
fi

if [ "$(git symbolic-ref --short HEAD)" != "master" ]; then
	echo "Currently checkout out branch must be 'master'" >&2
	exit 1
fi

if [ $(git status --porcelain | wc -l) != 0 ]; then
	echo "Working copy contains uncommitted changes" >&2
	exit 1
fi

if [ $(git ls-remote --tags origin v$ver | wc -l) != 0 ]; then
	echo "Version $ver already released (remote tag v$ver already exists)" >&2
	exit 1
fi

echo "Updating trumicount (setting version to $ver)" >&2
sed -i.bak 's/^VERSION <- .*$/VERSION <- "'"$ver"'"/' trumicount
rm trumicount.bak

echo "Updating manual/manual.tex (setting version to $ver)" >&2
sed -i.bak 's/^\\version{.*}$/\\version{'"$ver"'}/' manual/manual.tex
rm manual/manual.tex.bak

echo "Updating manual/reference.tex" >&2
(cd manual; ./make-reference-tex)

echo "Updating manual/manual.pdf" >&2
(cd manual; for i in 1 2 3; do pdflatex -interaction batchmode -shell-escape manual.tex >/dev/null 2>&1; done)

echo "Comitting change" >&2
git add trumicount manual/manual.tex manual/reference.tex manual/manual.pdf
git commit -m "Incremented version to $ver"

echo "Tagging as v$ver and latest" >&2
git tag -f v$ver

echo "Pushing to origin" >&2
git push origin master v$ver

echo "Updating 'latest' on origin" >&2
git push -f origin v$ver:refs/tags/latest-release
