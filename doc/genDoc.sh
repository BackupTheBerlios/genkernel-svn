#!/bin/sh

echo "Generating HTML..."
asciidoc -b xhtml11 genkernel.8.txt
asciidoc -b xhtml11 HOWTO-Genkernel-SSI.txt

### TODO: Asciidoc 7.1+ has a manpage generation wrapper (see `a2x`)
### but Asciidoc 7.1+ is not in portage yet
echo "Generating manpage..."
asciidoc -b docbook -d manpage genkernel.8.txt
xsltproc genkernel.8.xsl genkernel.8.xml
