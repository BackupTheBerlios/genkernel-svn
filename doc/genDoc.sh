#!/bin/sh

echo "Generating HTML..."
asciidoc genkernel.8.txt

echo "Generating manpage..."
asciidoc -b docbook -d manpage genkernel.8.txt
xsltproc genkernel.8.xsl genkernel.8.xml
