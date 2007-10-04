#require kernel_config
#logicTrue $(profile_get_key internal-uclibc) && require gcc

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/aoetools-${AOETOOLS_VER}.tar.gz"

aoetools_compile::()
{
	local AOETOOLS_SRCTAR="${SRCPKG_DIR}/aoetools-${AOETOOLS_VER}.tar.gz" AOETOOLS_DIR="aoetools-${AOETOOLS_VER}"
    local COMMANDS

		cd "${TEMP}"
		rm -rf ${AOETOOLS_DIR} > /dev/null
		unpack ${AOETOOLS_SRCTAR} || die 'Could not extract aoetools source tarball!'
		[ -d "${AOETOOLS_DIR}" ] || die 'aoetools directory ${AOETOOLS_DIR} is invalid!'
		cd "${AOETOOLS_DIR}" > /dev/null	
		gen_patch ${FIXES_PATCHES_DIR}/aoetools/${AOETOOLS_VER} .
        
        # turn on/off the cross compiler
        if [ -n "$(profile_get_key cross-compile)" ]
        then
            ARGS="${ARGS} CC=$(profile_get_key cross-compile)-gcc"
        else
            [ -n "$(profile_get_key utils-cross-compile)" ] && \
                ARGS="${ARGS} CC=$(profile_get_key utils-cross-compile)-gcc"
        fi

		print_info 1 "Compiling aoetools utilities"

        compile_generic ${ARGS} # Compile
        #ARGS="${ARGS} DESTDIR=${TEMP}/aoetools-output"
        #compile_generic ${ARGS} install # Install

		[ -e ${TEMP}/aoetools-output ] && rm -rf ${TEMP}/aoetools-output
		mkdir -p ${TEMP}/aoetools-output/sbin
        COMMANDS="aoe-discover aoe-interfaces aoe-mkshelf aoe-revalidate aoe-flush aoe-stat aoe-mkdevs aoe-version aoeping"
        for i in ${COMMANDS}
        do
            if [ "$(profile_get_key debuglevel)" -gt "1" ]
            then
                # Output to stdout and debugfile
                install -v -m 700 $i ${TEMP}/aoetools-output/sbin/$i 2>&1 |tee -a >${DEBUGFILE}
                RET=${PIPESTATUS[0]}
            else
                # Output to debugfile only
                install -v -m 700 $i ${TEMP}/aoetools-output/sbin/$i >>${DEBUGFILE} 2>&1
                RET=$?
            fi
            [ "${RET}" -eq '0' ] || die "Failed to install ..."
        done
		#[ -x "utils/unionctl" ] && cp utils/unionctl ${TEMP}/unionfs-output/sbin
		#[ -x "unionctl" ] && cp unionctl ${TEMP}/unionfs-output/sbin
		#strip ${TEMP}/unionfs-output/sbin/unionctl

		#cp unionimap ${TEMP}/unionfs-output/sbin
		#cp uniondbg ${TEMP}/unionfs-output/sbin
		#strip ${TEMP}/unionfs-output/sbin/unionimap
		#strip ${TEMP}/unionfs-output/sbin/uniondbg
		
		cd ${TEMP}/aoetools-output
		genkernel_generate_package "aoetools-${AOETOOLS_VER}" "."
		#genkernel_generate_cpio_path "unionfs-${UNIONFS_VER}" .
		#initramfs_register_cpio "unionfs-${UNIONFS_VER}"
	#fi
}
