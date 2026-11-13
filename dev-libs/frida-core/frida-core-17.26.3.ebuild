# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit flag-o-matic frida-core meson python-any-r1

DESCRIPTION="Frida core: dynamic instrumentation toolkit library, built as a static devkit"
HOMEPAGE="https://frida.re/ https://github.com/frida/frida-core"
SRC_URI="${FRIDA_CORE_SRC_URI}"
S=${WORKDIR}/${P}

LICENSE="wxWinLL-3.1 LGPL-2.1+ BSD MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="${FRIDA_CORE_DEPEND}"
RDEPEND="${DEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	${FRIDA_CORE_BDEPEND}
"

pkg_setup() {
	[[ ${PV} == "${FRIDA_CORE_PV}" ]] || die "frida-core.eclass pins ${FRIDA_CORE_PV}, not ${PV}"
	python-any-r1_pkg_setup
}

src_unpack() {
	frida-core_unpack "${S}"
}

src_prepare() {
	frida-core_patch "${S}"
	default
}

src_configure() {
	frida-core_setup_env
	frida-core_emesonargs ""

	local emesonargs=(
		"${FRIDA_CORE_EMESONARGS[@]}"
		--force-fallback-for=glib-2.0,gobject-2.0,gio-2.0,gio-unix-2.0,gmodule-2.0,gthread-2.0,json-glib-1.0,gee-0.8,capstone
	)
	meson_src_configure
}

src_install() {
	# The devkit is what frida bindings link against.
	insinto /usr/$(get_libdir)/${PN}/devkit
	doins "${BUILD_DIR}"/src/devkit/{frida-core.h,libfrida-core.a}
}
