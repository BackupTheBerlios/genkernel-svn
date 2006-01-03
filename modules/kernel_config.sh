config_kernel::()
{

config_set_key kernel-tree '/usr/src/linux'
config_set_key kbuild_output '/tmp/genkernel/2.6.14'
#config_set_key arch 'i386'
config_set_key install_path '/tmp/genkernel/2.6.14/output'
config_set_key install_mod_path '/tmp/genkernel/2.6.14/output'

mkdir -p $(config_get_key install_path)
mkdir -p $(config_get_key install_mod_path)

cd $(config_get_key kernel-tree)
# Source dir needs to be clean or kbuild complains

[ -n "$(config_get_key arch)" ] && ARGS="${ARGS} ARCH=$(config_get_key arch)"

[ -n "$(config_get_key kbuild_output)" ] && ARGS="${ARGS} KBUILD_OUTPUT=$(config_get_key kbuild_output)"
[ -n "$(config_get_key kbuild_output)" ] && mkdir -p $(config_get_key kbuild_output)

[ -n "$(config_get_key install_path)" ] && ARGS="${ARGS} INSTALL_PATH=$(config_get_key install_path)"
[ -n "$(config_get_key install_path)" ] && mkdir -p $(config_get_key install_path)

[ -n "$(config_get_key install_mod_path)" ] && ARGS="${ARGS} INSTALL_MOD_PATH=$(config_get_key install_mod_path)"
[ -n "$(config_get_key install_mod_path)" ] && mkdir -p $(config_get_key install_mod_path)

[ -n "$(config_get_key cross_compile)" ] && ARGS="${ARGS} CROSS_COMPILE=$(config_get_key cross_compile)"

compile_generic distclean

# Mr. proper needed?
[ -n "$(config_get_key mrproper)" ] && compile_generic ${ARGS} mrproper

yes '' 2>/dev/null | compile_generic ${ARGS} oldconfig
compile_generic ${ARGS}
compile_generic ${ARGS} modules
compile_generic ${ARGS} install
compile_generic ${ARGS} modules_install
}
