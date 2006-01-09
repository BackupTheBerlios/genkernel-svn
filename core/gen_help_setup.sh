#!/bin/bash
#  GROUP -> OPTION -> DATA (Boolean):[DEFAULT] -> Allow no'X' (Boolean) -> DESCRIPTION
## Debug
__register_config_option 'Debug' 'debuglevel' 'true' 'false' 'Debug verbosity level'
# Now set the debuglevel system default
config_set_key debuglevel '1' 'system'

__register_config_option 'Debug' 'debugfile'  'true' 'false' 'Output file for debug info'
config_set_key usecolor true 'system'

## Kernel Config
__register_config_option 'Kernel Configuration'	'menuconfig'	 'false' 'true'	 'Run menuconfig after oldconfig.'
__register_config_option 'Kernel Configuration'	'no-save-config' 'false' 'false' "Don't save the configuration to /etc/kernels."
__register_config_option 'Kernel Configuration'	'oldconfig'	 'false:true' 'false' 'Run oldconfig.'
__register_config_option 'Kernel Configuration'	'config'	 'false' 'false' 'Run config after oldconfig.'
__register_config_option 'Kernel Configuration'	'gconfig'	 'false' 'false' 'Run gconfig after oldconfig.'
__register_config_option 'Kernel Configuration'	'xconfig'	 'false' 'false' 'Run xconfig after oldconfig.'

## Kernel Compile
__register_config_option 'Kernel Compile' 'clean'		'false'	'true'	'Run "make clean" before compilation.'
__register_config_option 'Kernel Compile' 'install'		'false' 'true'	'Install the kernel to /boot after building; this does not change bootloader settings.'
__register_config_option 'Kernel Compile' 'mrproper'		'false' 'true'	'Run "make mrproper" before compilation.'
__register_config_option 'Kernel Compile' 'oldconfig'		'false' 'false' 'Implies "--no-clean" and runs a "make oldconfig".'
__register_config_option 'Kernel Compile' 'gensplash'		'true:true' 'false' 'Install gensplash support into bzImage optionally using the specified theme.'

## Kernel Settings
__register_config_option 'Kernel Settings' 'kernel-config' 'true' 'false' 'Kernel configuration file to use for compilation.'

__register_config_option 'Kernel Settings' 'kernel-tree'   'true' 'false' 'Location of kernel sources.'
# kernel-tree default
config_set_key kernel-tree '/usr/src/linux'

__register_config_option 'Kernel Settings' 'kbuild-output'   'true' 'false' 'Location of kernel sources.'
__register_config_option 'Kernel Settings' 'module-prefix' 'true' 'false' 'Prefix to kernel module destination, modules will be installed in <prefix>/lib/modules.'

## Low Level Kernel
# __register_config_option 'Low-Level' 'kernel-as' 'true' 'false' 'Assembler to use for kernel.'
# __register_config_option 'Low-Level' 'kernel-cc' 'true' 'false' 'Compiler to use for kernel.'
# __register_config_option 'Low-Level' 'kernel-ld' 'true' 'false' 'Linker to use for kernel.'
__register_config_option 'Low-Level' 'kernel-cross-compile' 'true' 'false' 'CROSS_COMPILE kernel variable.'
# __register_config_option 'Low-Level' 'kernel-make' 'true' 'false' 'Make to use for kernel.'

## Low Level Utils
# __register_config_option 'Low-Level' 'utils-as' 'true' 'false' 'Assembler to use for utilities.'
# __register_config_option 'Low-Level' 'utils-cc' 'true' 'false' 'Compiler to use for utilities.'
# __register_config_option 'Low-Level' 'utils-ld' 'true' 'false' 'Linker to use for utilities.'
# __register_config_option 'Low-Level' 'utils-make' 'true' 'false' 'Make to use for kernel.'

## Low Level Misc
__register_config_option 'Low-Level' 'makeopts' 'true' 'false' 'Global make options.'

## Init
__register_config_option 'Initialization' 'bootloader=grub' 'false' 'false' 'Add new kernel to GRUB configuration.'
__register_config_option 'Initialization' 'do-keymap-auto' 'false' 'false' 'Force keymap selection at boot.'
__register_config_option 'Initialization' 'evms2' 'false' 'false' 'Include EVMS2 support.'
__register_config_option 'Initialization' 'lvm2' 'false' 'false' 'Include LVM2 support.'
__register_config_option 'Initialization' 'disklabel' 'false' 'false' 'Include disk label and uuid support in your initramfs.'
__register_config_option 'Initialization' 'linuxrc' 'true' 'false' 'Use a user specified linuxrc.'
__register_config_option 'Initialization' 'gensplash-res' 'true' 'false' 'Gensplash resolutions to include; this is passed to splash_geninitramfs in the "-r" flag.'

## Catalyst Init Internals
__register_config_option 'Initialization' 'bladecenter' 'false' 'false' '' # Used by catalyst internally, hide option; 'Enables extra pauses for IBM Bladecenter CD boots.'
__register_config_option 'Initialization' 'unionfs' 'false' 'false' '' # Description empty, hide option

## Internals
__register_config_option 'Internals' 'arch-override' 'true' 'false' 'Force to arch instead of autodetecting.'
__register_config_option 'Internals' 'callback'	'true' 'false' 'Run the specified arguments after the kernel and modules have been compiled.'
__register_config_option 'Internals' 'cachedir' 'true' 'false' 'Override the default cache location.'
__register_config_option 'Internals' 'tempdir' 'true' 'false' "Location of Genkernel's temporary directory."
__register_config_option 'Internals' 'postclear' 'false' 'false' 'Clear all temporary files and caches afterwards.'
# Allow multiple entries for the profile
__register_config_option 'Internals' 'profile' 'true!m' 'false' 'Use specified profile.'
__register_config_option 'Internals' 'profile-dump' 'false' 'false' 'Use specified profile.'
__register_config_option 'Internals' 'mountboot' 'false' 'true' 'Mount /boot automatically.'
__register_config_option 'Internals' 'usecolor' 'false' 'true' 'Color output.'
# usecolor default
config_set_key usecolor true 'system'

## Output Settings
__register_config_option 'Output Settings' 'kerncache' 'true' 'false' "File to output a .tar.bz2'd kernel, the contents of /lib/modules/ and the kernel config; this is done before callbacks."
__register_config_option 'Output Settings' 'kernel-name' 'true' 'false' 'Tag the kernel and initrd with a name; if not defined the option defaults to "genkernel".'
__register_config_option 'Output Settings' 'initramfs-overlay' 'true' 'false' 'Directory structure to include in the initramfs.'
__register_config_option 'Output Settings' 'external-cpio' 'true!m' 'false' 'Include an external cpio file.'
#__register_config_option 'Output Settings' 'minkernpackage' 'true' 'false' "File to output a .tar.bz2'd kernel and initrd: No modules outside of the initrd will be included..."
#__register_config_option 'Output Settings' 'modulespackage' 'true' 'false' "File to output a .tar.bz2'd modules after the callbacks have run."
__register_config_option 'Output Settings' 'no-initrdmodules'	'false' 'false' 'Do not install any modules into the initramfs.'
#__register_config_option 'Output Settings' 'no-kernel-sources' 'false' 'false' 'If there is a valid kerncache no checks will be made against a kernel source tree.'
__register_config_option 'Output Settings' 'log-override' 'true' 'false' '' # Hide

## Miscellaneous
__register_config_option 'Miscellaneous' 'help' 'false' 'false' '' # Hidden.
