# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit flag-o-matic frida-core meson python-r1

DESCRIPTION="Dynamic instrumentation toolkit for developers, reverse-engineers, and researchers"
HOMEPAGE="https://frida.re/ https://github.com/frida/frida-python"

# frida-bindgen is a submodule of the release, pinned by the tag.
FRIDA_BINDGEN_REV=eace04901ef6300429e8c343095297df042dba0e

SRC_URI="
	https://github.com/frida/frida-python/archive/refs/tags/${PV}.tar.gz -> frida-python-${PV}.tar.gz
	https://github.com/frida/frida-bindgen/archive/${FRIDA_BINDGEN_REV}.tar.gz -> frida-bindgen-${FRIDA_BINDGEN_REV}.tar.gz
	${FRIDA_CORE_SRC_URI}
"
S=${WORKDIR}/frida-python-${PV}

LICENSE="wxWinLL-3.1 LGPL-2.1+ BSD MIT"
SLOT="0"
KEYWORDS="~amd64"
REQUIRED_USE=${PYTHON_REQUIRED_USE}

DEPEND="${FRIDA_CORE_DEPEND}"
RDEPEND="
	${PYTHON_DEPS}
	${DEPEND}
"
BDEPEND="
	${PYTHON_DEPS}
	${FRIDA_CORE_BDEPEND}
"

pkg_setup() {
	[[ ${PV} == "${FRIDA_CORE_PV}" ]] || die "frida-core.eclass pins ${FRIDA_CORE_PV}, not ${PV}"
	python_setup
}

src_unpack() {
	unpack frida-python-${PV}.tar.gz

	mkdir -p "${S}/frida-bindgen" || die
	tar -xzf "${DISTDIR}/frida-bindgen-${FRIDA_BINDGEN_REV}.tar.gz" -C "${S}/frida-bindgen" \
		--strip-components=1 || die "unpacking frida-bindgen"

	# The bindings are generated from the GIR files of frida-core, which is
	# built here as a subproject so that both share one copy of glib.
	frida-core_unpack "${S}/subprojects/frida-core"
}

src_prepare() {
	frida-core_patch "${S}/subprojects/frida-core"

	# Both projects look for releng at the top of the tree.
	rm -rf "${S}/releng" || die
	cp -a "${S}/subprojects/frida-core/releng" "${S}/releng" || die

	default
}

src_configure() {
	frida-core_setup_env
	frida-core_emesonargs "frida-core:"

	local emesonargs=(
		"${FRIDA_CORE_EMESONARGS[@]}"
		--force-fallback-for=frida-core-1.0,glib-2.0,gobject-2.0,gio-2.0,gio-unix-2.0,gmodule-2.0,gthread-2.0,json-glib-1.0,gee-0.8,capstone
	)
	meson_src_configure
}

src_install() {
	# The extension only uses the stable ABI, so one build serves every
	# interpreter.
	local stage=${T}/stage
	meson install -C "${BUILD_DIR}" --no-rebuild --destdir "${stage}" || die

	local pkgdir
	pkgdir=$(find "${stage}" -type d -name frida -path '*/site-packages/*' -print -quit)
	[[ -n ${pkgdir} ]] || die "the frida package was not installed"

	install_package() {
		python_moduleinto .
		python_domodule "${pkgdir}"
		python_optimize
	}
	python_foreach_impl install_package
}
