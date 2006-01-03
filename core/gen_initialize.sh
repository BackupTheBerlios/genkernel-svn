#!/bin/bash

TMPDIR='/var/tmp/genkernel'
TODEBUGCACHE=false # Until an error occurs or DEBUGFILE is fully qualified.
TEMP="${TMPDIR}/$RANDOM.$RANDOM.$RANDOM.$$"

# Find another directory if we clash
while [ -e "${TEMP}" ]
do
    TEMP="${TMPDIR}/$RANDOM.$RANDOM.$RANDOM.$$.$$"
done

#Internal flag to check if config parsing succeeded
__INTERNAL__CONFIG_PARSING_FAILED=false

#Set some defaults
config_set_key usecolor true
config_set_key kernel-tree '/usr/src/linux'
config_set_key debuglevel '1'

