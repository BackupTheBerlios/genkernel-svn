require kernel_config
#logicTrue $(profile_get_key internal-uclibc) && require gcc
open_iscsi_compile::()
{
	local OPENISCSI_SRCTAR="${SRCPKG_DIR}/open-iscsi-${OPENISCSI_VER}.tar.gz" OPENISCSI_DIR="open-iscsi-${OPENISCSI_VER}"
	[ -f "${OPENISCSI_SRCTAR}" ] || die "Could not find open-iscsi source tarball: ${OPENISCSI_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${OPENISCSI_DIR}"
	unpack "${OPENISCSI_SRCTAR}" || die "Failed to unpack open-iscsi sources!"
	[ ! -d "${OPENISCSI_DIR}" ] && die "open-iscsi directory ${OPENISCSI_DIR} invalid"

	cd "${OPENISCSI_DIR}"
	gen_patch ${FIXES_PATCHES_DIR}/open-iscsi/${OPENISCSI_VER} .
	
	# turn on/off the cross compiler
	#if [ -n "$(profile_get_key cross-compile)" ]
	#then
	#	ARGS="${ARGS} CC=$(profile_get_key cross-compile)gcc"
    #else
	#	[ -n "$(profile_get_key utils-cross-compile)" ] && \
	#		ARGS="${ARGS} CC=$(profile_get_key utils-cross-compile)gcc"
	#fi

    OPENISCSI_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
		-e 's/x86/i386/' \
		-e 's/i.86/i386/' \
		-e 's/sparc.*/sparc/' \
		-e 's/arm.*/arm/g' \
		-e 's/m68k.*/m68k/' \
		-e 's/ppc/powerpc/g' \
		-e 's/v850.*/v850/g' \
		-e 's/sh[234].*/sh/' \
		-e 's/mips.*/mips/' \
		-e 's/mipsel.*/mips/' \
		-e 's/cris.*/cris/' \
		-e 's/nios2.*/nios2/' \
	)

	print_info 1 'open-iscsi: >> Compiling...'
	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then
		compile_generic KSRC=$(profile_get_key kernel-tree) KBUILD_OUTPUT=$(profile_get_key kbuild-output) KARCH=ARCH=${OPENISCSI_TARGET_ARCH}
	else
		compile_generic KSRC=$(profile_get_key kernel-tree) KARCH=ARCH=${OPENISCSI_TARGET_ARCH}
	fi
	

	
#	[ -e "${TEMP}/portmap-compile" ] && rm -r ${TEMP}/portmap-compile
#    mkdir -p ${TEMP}/portmap-compile/sbin
#
#    cp portmap ${TEMP}/portmap-compile/sbin
#    cp pmap_dump ${TEMP}/portmap-compile/sbin
#    cp pmap_set ${TEMP}/portmap-compile/sbin
#    cd ${TEMP}/portmap-compile
#
#	strip "${TEMP}/portmap-compile/sbin/portmap" || die 'Could not strip portmap binary!'
#	strip "${TEMP}/portmap-compile/sbin/pmap_dump" || die 'Could not strip pmap_dump binary!'
#	strip "${TEMP}/portmap-compile/sbin/pmap_set" || die 'Could not strip pmap_set binary!'
#    genkernel_generate_package "portmap-${PORTMAP_VER}" "."
#	
#	cd ${TEMP}
#
#	rm -rf "${PORTMAP_DIR}" > /dev/null
#	rm -rf "${TEMP}/portmap-compile" > /dev/null
}
