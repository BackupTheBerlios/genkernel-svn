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



# For debugging purposes only ... remove at later date
config_set_key kbuild-output '/tmp/genkernel/2.6.14'
# config_set_key arch 'i386'
config_set_key install-path '/tmp/genkernel/2.6.14/output'
config_set_key install-mod-path '/tmp/genkernel/2.6.14/output'
# config_set_key clean true
config_set_key oldconfig true
# config_set_key menuconfig true
# config_set_key gconfig true
# config_set_key xconfig true

