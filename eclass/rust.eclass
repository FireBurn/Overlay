# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: rust.eclass
# @MAINTAINER:
# Matt Jolly <kangie@gentoo.org>
# @AUTHOR:
# Matt Jolly <kangie@gentoo.org>
# @SUPPORTED_EAPIS: 8
# @BLURB: Utility functions to build against slotted Rust
# @DESCRIPTION:
# An eclass to reliably depend on a Rust or Rust/LLVM combination for
# a given Rust slot. To use the eclass:
#
# 1. If required, set RUST_{MAX,MIN}_VER to the range of supported slots.
#
# 2. If rust is optional, set RUST_OPTIONAL to a non-empty value then
#    appropriately gate ${RUST_DEPEND}.
#
# 3. Use rust_pkg_setup, get_rust_prefix, or RUST_SLOT.

# Example use for a package supporting Rust 1.72.0 to 1.82.0:
# @CODE
#
# RUST_MAX_VER="1.82.0"
# RUST_MIN_VER="1.72.0"
#
# inherit meson rust
#
# # only if you need to define one explicitly
# pkg_setup() {
#	rust_pkg_setup
#	do-something-else
# }
# @CODE
#
# Example for a package needing Rust w/ a specific target:
# @CODE
# RUST_REQ_USE='clippy'
# RUST_MULTILIB=1
#
# inherit multilib-minimal meson rust
#
# @CODE

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_RUST_ECLASS} ]]; then
_RUST_ECLASS=1

if [[ -n ${RUST_MULTILIB} ]]; then
	inherit multilib-build
	RUST_REQ_USE="${RUST_REQ_USE+${RUST_REQ_USE},}${MULTILIB_USEDEP}"
fi

# == internal control knobs ==

# @ECLASS_VARIABLE: _RUST_LLVM_MAP
# @INTERNAL
# @DESCRIPTION:
# LLVM slots supported by each Rust slot.
declare -A -g -r _RUST_LLVM_MAP=(
	["9999"]="23 22 21"
	["1.98.1"]="23 22 21"
	["1.98.0"]="23 22 21"
	["1.97.1"]="22 21"
	["1.96.1"]="22 21"
	["1.95.0"]="22 21 20"
	["1.94.1"]="22 21 20"
	["1.94.0"]="22 21 20"
	["1.93.1"]="21 20"
	["1.93.0"]="21 20"
	["1.92.0"]="21 20"
	["1.91.0"]="21 20 19"
	["1.90.0"]="20 19"
	["1.89.0"]="20 19"
	["1.88.0"]="20 19"
	["1.87.0"]="20 19"
	["1.86.0"]="19 18"
	["1.85.1"]="19 18"
	["1.85.0"]="19 18"
	["1.84.1"]="19 18"
	["1.84.0"]="19 18"
	["1.83.0"]="19 18"
	["1.82.0"]="19 18"
	["1.81.0"]="18 17"
	["1.80.1"]="18 17"
	["1.79.0"]="18 17"
	["1.78.0"]="18 17 16"
	["1.77.1"]="17 16"
	["1.76.0"]="17 16"
	["1.75.0"]="17 16 15"
	["1.74.1"]="17 16 15"
)

# @ECLASS_VARIABLE: _RUST_SLOTS_ORDERED
# @INTERNAL
# @DESCRIPTION:
# Array of Rust slots, newest first.
_rust_order_slots() {
	local slot i
	_RUST_SLOTS_ORDERED=()
	for slot in "${!_RUST_LLVM_MAP[@]}"; do
		for (( i=0; i<${#_RUST_SLOTS_ORDERED[@]}; i++ )); do
			ver_test "${slot}" -gt "${_RUST_SLOTS_ORDERED[i]}" && break
		done
		_RUST_SLOTS_ORDERED=( "${_RUST_SLOTS_ORDERED[@]:0:i}" "${slot}" "${_RUST_SLOTS_ORDERED[@]:i}" )
	done
	readonly -a _RUST_SLOTS_ORDERED
}
_rust_order_slots
unset -f _rust_order_slots

# @ECLASS_VARIABLE: RUST_LLVM_COMPAT
# @PRE_INHERIT
# @DESCRIPTION:
# Rust slot whose LLVM compatibility supplies LLVM_COMPAT when building Rust.
# Set before inheriting rust and llvm-r2.
if [[ -n ${RUST_LLVM_COMPAT} ]]; then
	[[ -n ${_RUST_LLVM_MAP[${RUST_LLVM_COMPAT}]} ]] || die "Unknown Rust slot: ${RUST_LLVM_COMPAT}"
	LLVM_COMPAT=()
	for _rust_llvm_slot in ${_RUST_LLVM_MAP[${RUST_LLVM_COMPAT}]}; do
		LLVM_COMPAT=( "${_rust_llvm_slot}" "${LLVM_COMPAT[@]}" )
	done
	unset _rust_llvm_slot
fi

if [[ -n ${RUST_NEEDS_LLVM} ]]; then
	inherit llvm-r2
fi

# == user control knobs ==

# @ECLASS_VARIABLE: ERUST_SLOT_OVERRIDE
# @USER_VARIABLE
# @DESCRIPTION:
# Specify the version (slot) of Rust to be used by the package. This is
# useful for troubleshooting and debugging purposes. If unset, the newest
# acceptable Rust version will be used. May be combined with ERUST_TYPE_OVERRIDE.
# This variable must not be set in ebuilds.

# @ECLASS_VARIABLE: ERUST_TYPE_OVERRIDE
# @USER_VARIABLE
# @DESCRIPTION:
# Specify the type of Rust to be used by the package from options:
# 'source' or 'binary' (-bin). This is useful for troubleshooting and
# debugging purposes. If unset, the standard eclass logic will be used
# to determine the type of Rust to use (i.e. prefer source if binary
# is also available). May be combined with ERUST_SLOT_OVERRIDE.
# This variable must not be set in ebuilds.

# == control variables ==

# @ECLASS_VARIABLE: RUST_MAX_VER
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Highest Rust slot supported by the package. Needs to be set before
# rust_pkg_setup is called. If unset, no upper bound is assumed.

# @ECLASS_VARIABLE: RUST_MIN_VER
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Lowest Rust slot supported by the package. Needs to be set before
# rust_pkg_setup is called. If unset, no lower bound is assumed.

# @ECLASS_VARIABLE: RUST_SOURCE_ONLY
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Require source-built Rust when compiler components are unavailable in rust-bin.

# @ECLASS_VARIABLE: RUST_SLOT
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# The selected Rust slot for building, from the range defined by
# RUST_MAX_VER and RUST_MIN_VER. This is set by rust_pkg_setup.

# @ECLASS_VARIABLE: RUST_TYPE
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# The selected Rust type for building, either 'source' or 'binary'.
# This is set by rust_pkg_setup.

# @ECLASS_VARIABLE: RUST_NEEDS_LLVM
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-empty value generate a llvm_slot_${llvm_slot}? gated
# dependency block for rust slots in LLVM_COMPAT. This is useful for
# packages that need a tight coupling between Rust and LLVM but don't
# really care _which_ version of Rust is selected. Combine with
# RUST_MAX_VER and RUST_MIN_VER to limit the range of Rust versions
# that are acceptable. Will `die` if llvm-r2 is not inherited or
# an invalid combination of RUST and LLVM slots is detected; this probably
# means that a LLVM slot in LLVM_COMPAT has had all of its Rust slots filtered.

# @ECLASS_VARIABLE: RUST_MULTILIB
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-empty value insert MULTILIB_USEDEP into the generated
# Rust dependency. For this to be useful inherit a multilib eclass and
# configure the appropriate phase functions.

# @ECLASS_VARIABLE: RUST_DEPEND
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# This is an eclass-generated Rust dependency string, filtered by
# RUST_MAX_VER and RUST_MIN_VER. If RUST_NEEDS_LLVM is set, this
# is grouped and gated by an appropriate `llvm_slot_x` USE for all
# implementations listed in LLVM_COMPAT.

# @ECLASS_VARIABLE: RUST_OPTIONAL
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-empty value, the Rust dependency will not be added
# to BDEPEND. This is useful for packages that need to gate rust behind
# certain USE themselves.

# @ECLASS_VARIABLE: RUST_REQ_USE
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Additional USE-dependencies to be added to the Rust dependency.
# This is useful for packages that need to depend on specific Rust
# features, like clippy or rustfmt. The variable is expanded before
# being used in the Rust dependency.

# == global metadata ==

_rust_set_globals() {
	debug-print-function ${FUNCNAME} "$@"

	# If RUST_MIN_VER is older than our oldest slot we'll just set it to that
	# internally so we don't have to worry about it later.
	if ver_test "${_RUST_SLOTS_ORDERED[-1]}" -gt "${RUST_MIN_VER:-0}"; then
		RUST_MIN_VER="${_RUST_SLOTS_ORDERED[-1]}"
	fi

	# and if it falls between slots we'll set it to the next highest slot
	# We can skip this we match a slot exactly.
	if [[ "${_RUST_SLOTS_ORDERED[@]}" != *"${RUST_MIN_VER}"* ]]; then
		local i
		for (( i=${#_RUST_SLOTS_ORDERED[@]}-1 ; i>=0 ; i-- )); do
			if ver_test "${_RUST_SLOTS_ORDERED[$i]}" -gt "${RUST_MIN_VER}"; then
				RUST_MIN_VER="${_RUST_SLOTS_ORDERED[$i]}"
				break
			fi
		done
	fi

	if [[ -n "${RUST_MAX_VER}" && -n "${RUST_MIN_VER}" ]]; then
		if ! ver_test "${RUST_MAX_VER}" -ge "${RUST_MIN_VER}"; then
			die "RUST_MAX_VER must not be older than RUST_MIN_VER"
		fi
	fi

	local slot
	# Try to keep this in order of newest to oldest
	for slot in "${_RUST_SLOTS_ORDERED[@]}"; do
		if ver_test "${slot}" -le "${RUST_MAX_VER:-9999}" &&
			ver_test "${slot}" -ge "${RUST_MIN_VER:-0}"
			then
				_RUST_SLOTS+=( "${slot}" )
		fi
	done

	_RUST_SLOTS=( "${_RUST_SLOTS[@]}" )
	readonly _RUST_SLOTS

	local rust_dep=()
	local llvm_slot
	local rust_slot rust_package
	local rust_packages=( dev-lang/rust-bin dev-lang/rust )
	[[ -n ${RUST_SOURCE_ONLY} ]] && rust_packages=( dev-lang/rust )
	local usedep="${RUST_REQ_USE+[${RUST_REQ_USE}]}"

	# If we're not using LLVM, we can just generate a simple Rust dependency
	if [[ -z "${RUST_NEEDS_LLVM}" ]]; then
		rust_dep=( "|| (" )
		# We can be more flexible if we generate a simpler, open-ended dependency
		# when we don't have a max version set.
		if [[ -z "${RUST_MAX_VER}" ]]; then
			for rust_package in "${rust_packages[@]}"; do
				rust_dep+=( ">=${rust_package}-${RUST_MIN_VER}:*${usedep}" )
			done
		else
			# depend on each slot between RUST_MIN_VER and RUST_MAX_VER; it's a bit specific but
			# won't hurt as we only ever add newer Rust slots.
			for slot in "${_RUST_SLOTS[@]}"; do
				for rust_package in "${rust_packages[@]}"; do
					rust_dep+=( "${rust_package}:${slot}${usedep}" )
				done
			done
		fi
		rust_dep+=( ")" )
		RUST_DEPEND="${rust_dep[*]}"
	else
		for llvm_slot in "${_LLVM_SLOTS[@]}"; do
			usedep="[llvm_slot_${llvm_slot}(-)${RUST_REQ_USE+,${RUST_REQ_USE}}]"
			local slot_dep_content=()
			for rust_slot in "${_RUST_SLOTS[@]}"; do
				if has "${llvm_slot}" ${_RUST_LLVM_MAP[${rust_slot}]}; then
					for rust_package in "${rust_packages[@]}"; do
						slot_dep_content+=( "${rust_package}:${rust_slot}${usedep}" )
					done
				fi
			done
			[[ ${#slot_dep_content[@]} -gt 0 ]] || die "No Rust slots found for LLVM slot ${llvm_slot}"
			rust_dep+=( "llvm_slot_${llvm_slot}? ( || ( ${slot_dep_content[*]} ) )" )
		done
		RUST_DEPEND="${rust_dep[*]}"
	fi

	readonly RUST_DEPEND
	if [[ -z ${RUST_OPTIONAL} ]]; then
		BDEPEND="${RUST_DEPEND}"
	fi
}
_rust_set_globals
unset -f _rust_set_globals

# == ebuild helpers ==

# @FUNCTION: _get_rust_slot
# @USAGE: [-b|-d]
# @INTERNAL
# @DESCRIPTION:
# Find the newest Rust install that is acceptable for the package,
# and export its version (i.e. SLOT) and type (source or bin[ary])
# as RUST_SLOT and RUST_TYPE.
#
# If -b is specified, the checks are performed relative to BROOT,
# and BROOT-path is returned. -b is the default.
#
# If -d is specified, the checks are performed relative to ESYSROOT,
# and ESYSROOT-path is returned.
#
# If RUST_M{AX,IN}_VER is non-zero, then only Rust versions that
# are not newer or older than the specified slot(s) will be considered.
# Otherwise, all Rust versions are considered acceptable.
#
# If the `rust_check_deps()` function is defined within the ebuild, it
# will be called to verify whether a particular slot is acceptable.
# Within the function scope, RUST_SLOT and LLVM_SLOT will be defined.
#
# The function should return a true status if the slot is acceptable,
# false otherwise. A suitable Rust package must also be installed.
_get_rust_slot() {
	debug-print-function ${FUNCNAME} "$@"

	local hv_switch=-b
	while [[ ${1} == -* ]]; do
		case ${1} in
			-b|-d) hv_switch="${1}";;
			*) break;;
		esac
		shift
	done

	case ${ERUST_TYPE_OVERRIDE} in
		""|source|binary) ;;
		*) die "Invalid ERUST_TYPE_OVERRIDE: ${ERUST_TYPE_OVERRIDE}" ;;
	esac

	if [[ -n ${RUST_SOURCE_ONLY} && ${ERUST_TYPE_OVERRIDE} == binary ]]; then
		die "This package requires source-built Rust"
	fi

	local slot llvm_r1_slot
	if [[ -n ${RUST_NEEDS_LLVM} ]]; then
		for slot in "${_LLVM_SLOTS[@]}"; do
			if use "llvm_slot_${slot}"; then
				[[ -z ${llvm_r1_slot} ]] || die "Multiple LLVM slots selected"
				llvm_r1_slot=${slot}
			fi
		done
		[[ -n ${llvm_r1_slot} ]] || die "No LLVM slot selected"
	fi

	for slot in "${_RUST_SLOTS_ORDERED[@]}"; do
		ver_test "${slot}" -ge "${RUST_MIN_VER:-0}" || continue
		ver_test "${slot}" -le "${RUST_MAX_VER:-9999}" || continue

		if [[ -n "${ERUST_SLOT_OVERRIDE}" && "${slot}" != "${ERUST_SLOT_OVERRIDE}" ]]; then
			continue
		fi

		# If we're in LLVM mode we can skip any slots that don't match the selected USE
		if [[ -n "${RUST_NEEDS_LLVM}" ]]; then
			if ! has "${llvm_r1_slot}" ${_RUST_LLVM_MAP[${slot}]}; then
				einfo "Skipping Rust ${slot} as it does not match llvm_slot_${llvm_r1_slot}"
				continue
			fi
		fi

		einfo "Checking whether Rust ${slot} is suitable ..."

		if declare -f rust_check_deps >/dev/null; then
			_rust_check_slot_deps "${slot}" "${llvm_r1_slot:-${_RUST_LLVM_MAP[${slot}]%% *}}" || continue
		fi
		local usedep="${RUST_REQ_USE+[${RUST_REQ_USE}]}"
		if [[ -n ${RUST_NEEDS_LLVM} ]]; then
			usedep="[llvm_slot_${llvm_r1_slot}(-)${RUST_REQ_USE+,${RUST_REQ_USE}}]"
		fi
		# When checking for installed packages prefer the source package;
		# if effort was put into building it we should use it.
		local rust_pkgs
		case "${ERUST_TYPE_OVERRIDE}" in
			source)
				rust_pkgs=(
					"dev-lang/rust:${slot}${usedep}"
				)
				;;
			binary)
				rust_pkgs=(
					"dev-lang/rust-bin:${slot}${usedep}"
				)
				;;
			*)
				rust_pkgs=(
					"dev-lang/rust:${slot}${usedep}"
					"dev-lang/rust-bin:${slot}${usedep}"
				)
				;;
		esac
		if [[ -n ${RUST_SOURCE_ONLY} ]]; then
			rust_pkgs=( "dev-lang/rust:${slot}${usedep}" )
		fi
		local _pkg
		for _pkg in "${rust_pkgs[@]}"; do
			einfo " Checking for ${_pkg} ..."
			if has_version "${hv_switch}" "${_pkg}"; then
				export RUST_SLOT="${slot}"
				if [[ "${_pkg}" == "dev-lang/rust:${slot}${usedep}" ]]; then
					export RUST_TYPE="source"
				else
					export RUST_TYPE="binary"
				fi
				return
			fi
		done

	done

	local requirement_msg=""
	[[ -n "${RUST_MAX_VER}" ]] && requirement_msg+="<= ${RUST_MAX_VER} "
	[[ -n "${RUST_MIN_VER}" ]] && requirement_msg+=">= ${RUST_MIN_VER} "
	[[ -n "${RUST_REQ_USE}" ]] && requirement_msg+="with USE=${RUST_REQ_USE}"
	requirement_msg="${requirement_msg% }"
	die "No Rust matching requirements${requirement_msg:+ (${requirement_msg})} found installed!"
}

# @FUNCTION: _rust_check_slot_deps
# @INTERNAL
# @DESCRIPTION:
# Run the consumer's dependency check with the candidate slots in scope.
_rust_check_slot_deps() {
	local RUST_SLOT=${1} LLVM_SLOT=${2}
	rust_check_deps
}

# @FUNCTION: get_rust_path
# @USAGE: prefix slot rust_type
# @DESCRIPTION:
# Given arguments of prefix, slot, and rust_type, return an appropriate path
# for the Rust install. The rust_type should be either "source"
# or "binary". If the rust_type is not one of these, the function
# will die.
get_rust_path() {
	debug-print-function ${FUNCNAME} "$@"

	local prefix="${1}"
	local slot="${2}"
	local rust_type="${3}"

	if [[ ${#} -ne 3 ]]; then
		die "${FUNCNAME}: invalid number of arguments"
	fi

	case ${rust_type} in
		source) echo "${prefix}/usr/lib/rust/${slot}/";;
		binary) echo "${prefix}/opt/rust-bin-${slot}/";;
		*) die "${FUNCNAME}: invalid rust_type=${rust_type}";;
	esac
}

# @FUNCTION: get_rust_prefix
# @USAGE: [-b|-d]
# @DESCRIPTION:
# Find the newest Rust install that is acceptable for the package,
# and print an absolute path to it. If both -bin and regular Rust
# are installed, the regular Rust is preferred.
#
# The options and behavior are the same as _get_rust_slot.
get_rust_prefix() {
	debug-print-function ${FUNCNAME} "$@"

	local prefix=${BROOT}
	[[ ${1} == -d ]] && prefix=${ESYSROOT}

	_get_rust_slot "$@"
	get_rust_path "${prefix}" "${RUST_SLOT}" "${RUST_TYPE}"
}

# @FUNCTION: rust_prepend_path
# @USAGE: <slot> <type>
# @DESCRIPTION:
# Prepend the path to the specified Rust to PATH and re-export it.
rust_prepend_path() {
	debug-print-function ${FUNCNAME} "$@"

	[[ ${#} -ne 2 ]] && die "Usage: ${FUNCNAME} <slot> <type>"
	export PATH="$(get_rust_path "${BROOT}" "$@")/bin:${PATH}"
}

# @FUNCTION: rust_pkg_setup
# @DESCRIPTION:
# Prepend the appropriate executable directory for the newest
# acceptable Rust slot to the PATH. If used with LLVM, an appropriate
# `llvm-r2_pkg_setup` call should be made in addition to this function.
# For path determination logic, please see the get_rust_prefix documentation.
#
# The highest acceptable Rust slot can be set in the RUST_MAX_VER variable.
# If it is unset or empty, any slot is acceptable.
#
# The lowest acceptable Rust slot can be set in the RUST_MIN_VER variable.
# If it is unset or empty, any slot is acceptable.
#
# `CARGO` and `RUSTC` variables are set for the selected slot and exported.
#
# The PATH manipulation is only done for source builds. The function
# is a no-op when installing a binary package.
#
# If any other behavior is desired, the contents of the function
# should be inlined into the ebuild and modified as necessary.
rust_pkg_setup() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${MERGE_TYPE} != binary ]]; then
		_get_rust_slot -b
		rust_prepend_path "${RUST_SLOT}" "${RUST_TYPE}"
		local prefix=$(get_rust_path "${BROOT}" "${RUST_SLOT}" "${RUST_TYPE}")
		CARGO="${prefix}bin/cargo"
		RUSTC="${prefix}bin/rustc"
		export CARGO RUSTC
		einfo "Using Rust ${RUST_SLOT} (${RUST_TYPE})"
	fi
}

fi

EXPORT_FUNCTIONS pkg_setup
