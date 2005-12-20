# require 'module'
# Load module and add module to dependency order generation table
# This is multi-load safe but is coded to die if a circular dependency is found... since those are well, bad.

declare -a __INTERNAL__DEPS__REQ_N # Name
declare -a __INTERNAL__DEPS__REQ_D # Data
declare -a __INTERNAL__DEPS__PRV_S # Source
declare -a __INTERNAL__DEPS__PRV_P # Provides
declare -a __MODULE__DEPS__VARS_N # Name
declare -a __MODULE__DEPS__VARS_D # Data

# provide_lookup provide
# Look up the module which provides "provide"; return null
# if no matches are found.
provide_lookup() {
	local source provides

	for (( n = 0 ; n <= ${#__INTERNAL__DEPS__PRV_S[@]}; ++n )) ; do
		source=${__INTERNAL__DEPS__PRV_S[${n}]}
		provides=${__INTERNAL__DEPS__PRV_P[${n}]}

		[ "$1" = "${provides}" ] && echo "${source}" && return
	done
}

# provide {list}
# {list}: list of provides to check and register with the calling module.
provide () {
	local myCaller myCheck
	myCaller=$(basename ${BASH_SOURCE[1]} .sh)

	# Check something does not already provide this functionality,
        # unless the module is the same in which case ignore the request.
	# If no clashes are found commit the change.

	for i in $*; do
		myCheck=$(provide_lookup $i)

		if [ -n "${myCheck}" -a "${myCheck}" != "${myCaller}" ]
		then
			echo "Conflicting provide ($i in ${myCaller} against $i in ${myCheck})..."
			exit 1 # XXX XXX XXX
		else
			__INTERNAL__DEPS__PRV_S[${#__INTERNAL__DEPS__PRV_S[@]}]="${myCaller}"
			__INTERNAL__DEPS__PRV_P[${#__INTERNAL__DEPS__PRV_P[@]}]="$i"
		fi
	done
}

# require {list}
# {list}:item:	"xyz" - require module "xyz"
#		"@xyz" - require a module which provides the functionality "xyz"
#		"@xyz:yes:no" - require "yes" if a module that provides functionality "xyz"
#				exists, otherwise require "no"

#		"xyz:unset:one:two:three:..." - if the "xyz" module configuration key is unset,
#		a dependency on "unset" is formed or if the key is 0. If key is 1 require
#		"one", if the key is 2 require "two", etc.

#		"null" is a special target which does nothing and is not added to the deptree.
#		"fail" is another special target which halts deptree processing and informs
# 		that the deptree is unsatisfied.
require () {
	# Get Caller Module; step back twice in the execution list to get to the caller.
	local myCaller myDeps myConditonalVar myLookup
	myCaller=$(basename ${BASH_SOURCE[1]} .sh)

	__INTERNAL__MODULES_LOADED="${__INTERNAL__MODULES_LOADED} ${__INTERNAL__MODULES_LOADING}"
	# Process dependency list
	for i in $*; do
		# Special-case for 'null'
		[ "${i}" = 'null' ] && continue

		# Process conditional provide-based deps:
		if [ "${i:0:1}" = '@' ]
		then
			# If we have no conditionality then we require that item's presence:

			if [ "${i/:/}" != "${i}" ]
			then
				# Get first term and strip @

				myLookup="${i%%:*}"
				myLookup="${myLookup:1}"
				myConditionalVar="$(provide_lookup ${myLookup})"

				if [ -n "${myConditionalVar}" ]
				then
					# Success - get the second field (strip first and then leading fields)

					myConditionalVar="${i#*:}"
					myConditionalVar="${myConditionalVar%%:*}"
				else
					# Get last field
					myConditionalVar="${i##*:}"
				fi

				# Special-case for 'null'
				[ "${myConditionalVar}" = 'null' ] && continue
				if [ "${myConditionalVar}" = 'fail' ]
				then
					echo "Error: module ${myCaller} requires functionality ${myLookup} which is"
					echo '       unresolved. Deptree creation failed.'
					exit 255 # XXX
				fi

				myDeps="${myDeps} ${myConditionalVar}"
				continue
			else
				# Check if we have the provide, otherwise fail.
				false
			fi
		fi

		# Process conditional var-defined deps:
		if [ "${i/:/}" != "${i}" ]
		then
			# Get first term (our variable name) and look it up
			myConditionalVar="${i%%:*}"
			myConditionalVar="$(require_dep_lookup ${myConditionalVar})"

			[ -z "${myConditionalVar}" ] && myConditionalVar=2 || myConditionalVar=$(( ${myConditionalVar} + 2 ))
			myDeps="${myDeps} $(echo ${i} | cut -d: -f${myConditionalVar})"

			continue
		fi

		# Otherwise just tag on the deps:
		myDeps="${myDeps} ${i}"
	done

	# For $myCaller deps are $myDeps
	__INTERNAL__DEPS__REQ_N[${#__INTERNAL__DEPS__REQ_N[@]}]="${myCaller}"
	__INTERNAL__DEPS__REQ_D[${#__INTERNAL__DEPS__REQ_D[@]}]="${myDeps}"

	for i in ${myDeps}; do
		if ! $(has "${i}" "${__INTERNAL__MODULES_LOADED}")
		then
			# This needs to be set here so a cyclic loop is not formed
			__INTERNAL__MODULES_LOADED="${__INTERNAL__MODULES_LOADED} ${__INTERNAL__MODULES_LOADING}"
			# echo ">> Loading: $i"

			__INTERNAL__MODULES_LOADING="$i"
			if [ ! -e "modules/$i.sh" ]
			then
				echo ">> Module request [$i] not resolvable: $i.sh not found; halting..."
				exit 255
			else
				source modules/$i.sh
			fi
		else
			# We may or may not have a cyclic loop. Traverse the call stack and see if $myCaller is in there.
			if require_SearchStackForRecursion "${myCaller}"
			then
				if require_SearchStackForRecursion "${i}"
				then
					echo ">> Cyclic loop detected in dependencies [$i:$myCaller]. Stopping recursive processing..."
					require_DebugStack
					exit 255
				fi
			fi
		fi
	done
}

require_dep_lookup() {
	local name data

        for (( n = 0 ; n <= ${#MODULE_DEPS__VARS_N[@]}; ++n )) ; do
		name=${MODULE__DEPS__VARS_N[${n}]}
		data=${MODULE__DEPS__VARS_D[${n}]}

		[ "${name}" = "$1" ] && echo "${data}" && return
        done	
}

require_lookup() {
	local name data

        for (( n = 0 ; n <= ${#__INTERNAL__DEPS__REQ_N[@]}; ++n )) ; do
		name=${__INTERNAL__DEPS__REQ_N[${n}]}
		data=${__INTERNAL__DEPS__REQ_D[${n}]}

		[ "${name}" = "$1" ] && echo "${data}" && return
        done
}

require_DebugStack() {
	local name data

        for (( n = 0 ; n <= ${#__INTERNAL__DEPS__REQ_N[@]}; ++n )) ; do
		name=${__INTERNAL__DEPS__REQ_N[${n}]}
		data=${__INTERNAL__DEPS__REQ_D[${n}]}
		echo "(${name}:${data})"
        done
}

require_DebugStack() {
	# From eselect

        echo "Call stack:" 1>&2
        for (( n = 1 ; n < ${#FUNCNAME[@]} ; ++n )) ; do
            funcname=${FUNCNAME[${n}]}
            sourcefile=$(basename ${BASH_SOURCE[$(( n - 1 ))]})
            lineno=${BASH_LINENO[$(( n - 1 ))]}
            echo "    * ${funcname} (${sourcefile}:${lineno})" 1>&2
        done
}

require_SearchStackForRecursion() {
	# Ignore the last n = since that is the original require call
	for (( n = 1 ; n < $(( ${#FUNCNAME[@]} - 1 )); ++n )) ; do
		[ "$(basename ${BASH_SOURCE[$(( n - 1 ))]} .sh)" = "$1" ] && return 0
	done

	return 1
}

# buildDepTreeGeneric 'module' [carryIn]
# 'module': module to develop a depedency tree for
# [carryIn]: do not assign, used internally for cyclic checks

buildDepTreeGeneric () {
	local localTree resultTree myDeps myDone returnVal
	myDeps=$(require_lookup $1)

	# Check if we are at the end of our tree, if so, return and
	# start recursing backwards...
        [ "${myDeps}" = '' ] && return
	myDone="$2"

	for dep in ${myDeps}; do
		myDone="$2" # I think we need this here rather than above...

		if ! has "${dep}" "${localTree}"
		then
			# See if this node has already been processed /in the recursion/. If it has, we're going
			# round so halt.
			has "${dep}" "${myDone}" && echo ">> Circular dependency: $dep" >/dev/stderr

			# Add dep to myDone so a recursive loop can be detected further on in the recursion
			# if it so happens.
			myDone="${myDone} ${dep}"

			# Find deps of ${dep}
			returnVal=$(buildDepTreeGeneric "${dep}" "${myDone}" "${3}a")

			# ${dep} doesn't need to be removed from ${myDone} as ${myDone} is reloaded
			# on each cycle anyway.

			# Add any new dependencies to our local output tree
			for result in ${returnVal}; do
				has "${result}" "${localTree}" || localTree="${localTree} ${result}"
			done

			# Add ${dep} to tree to tree as we've now processed ${dep}'s dependencies.
			localTree="${localTree} ${dep}"
		fi
	done

	echo $localTree # Return value
}

buildDepTreeSolution()
{
	local routeName myResult myRoute myOut

	# Keep building dep trees for nodes we haven't included, add them recursively to our
	# output tree and don't worry about duplicates just yet...
        for (( n = 0 ; n <= ${#__INTERNAL__DEPS__REQ_N[@]}; ++n )) ; do
		if ! has "${__INTERNAL__DEPS__REQ_N[${n}]}" "${myRoute}"
		then
			myResult=$(buildDepTreeGeneric ${__INTERNAL__DEPS__REQ_N[${n}]})
			myRoute="${myRoute} ${myResult} ${__INTERNAL__DEPS__REQ_N[${n}]}"
		fi
        done

	# The last process can add duplicates. Remove them; FIFO.
	for point in ${myRoute}; do
		if ! has "${point}" "${myOut}"
		then
			myOut="${myOut} ${point}"
		fi
	done

#	echo "Corrected Route:${myRoute}"
#	echo "Corrected Route:${myOut}"
	echo ${myOut} # return
}
# buildDepTreeSolution
