require kernel_modules_compile

kernel_modules_install::()
{

    if kernel_config_is_not_set "MODULES"; then
        print_info 1 ">> Modules not enabled in .config... skipping modules install"
    else
        cd $(profile_get_key install-to-prefix)
        [ ! -w "$(profile_get_key install-to-prefix)" ] \
            && die "Could not write to $(profile_get_key install-to-prefix).  Set install-to-prefix to a writeable directory or run as root."
        genkernel_extract_package "kernel-modules-${KV_FULL}"
        print_info 1 "Kernel modules installed in ${BOLD}$(profile_get_key install-to-prefix)${NORMAL}"
        print_info 1 "$( du -sh lib/modules/${KV_FULL} )"
        print_info 1 "Updating module dependencies"

        if [ "$(profile_get_key debuglevel)" -gt "4" ]
        then
            /sbin/depmod -v -b $(profile_get_key install-to-prefix) ${KV_FULL}
        else
            /sbin/depmod -b $(profile_get_key install-to-prefix) ${KV_FULL}
        fi
        kernel_cmdline_register "export KBUILD_OUTPUT=$(profile_get_key kbuild-output)"
# Commented out below as we can just use the KBUILD_OUTPUT env variable
# put it in an /etc/make.conf .. etc

#        print_info 1 "Preparing a build directory for eventual external modules"
#        build_dir="/usr/src/linux-${KV_FULL}-build"
#        output_build="${INSTO}${build_dir}"
#        mkdir -p "$output_build" 2>/dev/null
#        cd $(profile_get_key kernel-tree)
#
#        compile_generic O="${output_build}" mrproper
#        cp "$KBUILD_OUTPUT/Module.symvers" "$KBUILD_OUTPUT/.config" "$output_build"
#        compile_generic O="${output_build}" modules_prepare
#
#        # include2 contains a symlink, which we don't want for portability
#        # so : we copy everything locally
#        #
#        # According to the top-level kernel Makefile, this include2
#        # dir only contains an asm symlink.
#        cd "${output_build}"/include2
#        mkdir .tmp
#        cp -a asm/* .tmp
#        rm -f asm
#        mv .tmp asm
#
#        # fix the build symlink, remove the source one for portability
#        cd "${INSTO}/lib/modules/${KV_FULL}"
#        rm build source
#        ln -s ../../.."${build_dir}" build
    fi
}
