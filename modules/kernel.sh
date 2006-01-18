if logicTrue $(profile_get_key install)
then
	require kernel_install
else
	require kernel_compile
fi

kernel::() { true; }
