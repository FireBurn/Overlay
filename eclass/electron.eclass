# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: electron.eclass
# @MAINTAINER:
# Mike Lothian <fireburn@gentoo.org>
# @SUPPORTED_EAPIS: 8
# @BLURB: Build and install applications that run on a system dev-util/electron
# @DESCRIPTION:
# Helpers for Electron applications built from source.  The application
# runs on a slotted, source-built dev-util/electron instead of the prebuilt
# Electron that electron-builder would bundle.
#
# Native addons are built against that Electron's Node headers, and a
# launcher runs the installed application directory with it.
#
# @EXAMPLE:
# @CODE
# ELECTRON_SLOT=44
# inherit electron npm
#
# src_compile() {
# 	electron_setup_env
# 	npm_with_registry pnpm install --frozen-lockfile
# 	edo pnpm run build
# }
#
# src_install() {
# 	insinto "$(electron_app_dir)"
# 	doins -r package.json build node_modules
# 	electron_make_launcher myapp
# }
# @CODE

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_ELECTRON_ECLASS} ]]; then
_ELECTRON_ECLASS=1

# @ECLASS_VARIABLE: ELECTRON_SLOT
# @PRE_INHERIT
# @REQUIRED
# @DESCRIPTION:
# Major version of dev-util/electron the application runs on.
[[ -n ${ELECTRON_SLOT} ]] || die "${ECLASS}: ELECTRON_SLOT must be set before inherit"

# @ECLASS_VARIABLE: ELECTRON_DEPEND
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Dependency on the Electron slot.  Added to DEPEND and RDEPEND.
ELECTRON_DEPEND="dev-util/electron:${ELECTRON_SLOT}"
DEPEND="${ELECTRON_DEPEND}"
RDEPEND="${ELECTRON_DEPEND}"

# @FUNCTION: electron_home
# @DESCRIPTION:
# Prints the Electron installation directory, relative to EPREFIX.
electron_home() {
	echo "/usr/$(get_libdir)/electron-${ELECTRON_SLOT}"
}

# @FUNCTION: electron_app_dir
# @DESCRIPTION:
# Prints the directory the application is installed into.
electron_app_dir() {
	echo "/usr/$(get_libdir)/${PN}"
}

# @FUNCTION: electron_setup_env
# @DESCRIPTION:
# Points node-gyp and the electron npm package at the system Electron, so
# native addons build against its headers and ABI and nothing downloads an
# Electron binary.
electron_setup_env() {
	debug-print-function ${FUNCNAME} "$@"

	local home="${ESYSROOT}$(electron_home)"
	[[ -f ${home}/version ]] || die "${ECLASS}: dev-util/electron:${ELECTRON_SLOT} is not installed"

	export ELECTRON_VERSION=$(<"${home}/version")
	export ELECTRON_SKIP_BINARY_DOWNLOAD=1
	export ELECTRON_OVERRIDE_DIST_PATH="${home}"
	export npm_config_runtime=electron
	export npm_config_target="${ELECTRON_VERSION}"
	export npm_config_nodedir="${home}/node_headers"
	export npm_config_build_from_source=true
}

# @FUNCTION: electron_make_launcher
# @USAGE: <name> [app path] [extra electron args...]
# @DESCRIPTION:
# Installs /usr/bin/<name>, which runs the application with the system
# Electron.  The app path defaults to electron_app_dir.  ELECTRON_FLAGS
# from the environment is passed through, for example
# --ozone-platform-hint=auto.
electron_make_launcher() {
	debug-print-function ${FUNCNAME} "$@"

	local name=${1:?} app=${2:-$(electron_app_dir)}
	shift 2 2>/dev/null || shift $#

	newbin - "${name}" <<-EOF
	#!/bin/sh
	exec "${EPREFIX}$(electron_home)/electron" "${EPREFIX}${app}" ${*} \${ELECTRON_FLAGS} "\$@"
	EOF
}

fi
