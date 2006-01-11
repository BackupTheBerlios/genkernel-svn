cmdline_modules_register(){
	local i data
	data=$1
	if [ "${data}" == "${data%:*}" ]
	then
		kernel_modules="${data}"
		category="extra"
	else
		kernel_modules="${data#*:}"
		category="${data%:*}"
	fi

	for i in $kernel_modules
	do
		profile_append_key "${category}" "${i}" "modules-cmdline"
	done
}
