# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit flag-o-matic meson python-any-r1

DESCRIPTION="Frida core: dynamic instrumentation toolkit library, built as a static devkit"
HOMEPAGE="https://frida.re/ https://github.com/frida/frida-core"

# Every subproject is pinned by the wrap files of the release, and the
# build runs with downloads disabled, so each pin is a distfile of its own.
SRC_URI="
	https://github.com/frida/frida-core/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/frida/efni/archive/72f90afcc1f7c663db4de934e9f7ab9d3f67d4b1.tar.gz -> frida-efni-72f90afcc1f7c663db4de934e9f7ab9d3f67d4b1.tar.gz
	https://github.com/frida/frida-gum/archive/refs/tags/17.26.2.tar.gz -> frida-frida-gum-17.26.2.tar.gz
	https://github.com/frida-forks/capstone/archive/f919a03a5417e1c7ea3af7035225073437030ef2.tar.gz -> frida-forks-capstone-f919a03a5417e1c7ea3af7035225073437030ef2.tar.gz
	https://github.com/frida-forks/json-glib/archive/0242c39f1f60f844c9df41e83434251b06609e82.tar.gz -> frida-forks-json-glib-0242c39f1f60f844c9df41e83434251b06609e82.tar.gz
	https://github.com/frida-forks/libdwarf/archive/9ac8cc22cab54d72cb355a44e85db716a7006f47.tar.gz -> frida-forks-libdwarf-9ac8cc22cab54d72cb355a44e85db716a7006f47.tar.gz
	https://github.com/frida-forks/libsoup/archive/2537f36926436ef7ac7e2430c25755216ed54ca5.tar.gz -> frida-forks-libsoup-2537f36926436ef7ac7e2430c25755216ed54ca5.tar.gz
	https://github.com/frida-forks/libunwind/archive/733d7d1c73f3512d2a50add2337157fa385a7e6e.tar.gz -> frida-forks-libunwind-733d7d1c73f3512d2a50add2337157fa385a7e6e.tar.gz
	https://github.com/frida-forks/quickjs/archive/6f3b5b4827d4c81af85627d66fce2ec3c8ab70d0.tar.gz -> frida-forks-quickjs-6f3b5b4827d4c81af85627d66fce2ec3c8ab70d0.tar.gz
	https://github.com/frida-forks/tinycc/archive/c0b84021e3e5c8359a469b1af2bf4abd83a7a26a.tar.gz -> frida-forks-tinycc-c0b84021e3e5c8359a469b1af2bf4abd83a7a26a.tar.gz
	https://github.com/frida-forks/glib/archive/f11db6352345ad21deb5f5783bb988bfca2a3d85.tar.gz -> frida-forks-glib-f11db6352345ad21deb5f5783bb988bfca2a3d85.tar.gz
	https://gitlab.gnome.org/GNOME/gvdb/-/archive/2b42fc75f09dbe1cd1057580b5782b08f2dcb400/gvdb-2b42fc75f09dbe1cd1057580b5782b08f2dcb400.tar.gz -> gnome-gvdb-2b42fc75f09dbe1cd1057580b5782b08f2dcb400.tar.gz
	https://github.com/frida-forks/libbpf/archive/9c4e176810717e27b6990a8722b252fc1967667f.tar.gz -> frida-forks-libbpf-9c4e176810717e27b6990a8722b252fc1967667f.tar.gz
	https://github.com/frida-forks/libgee/archive/69621d2c665b75c1e064abdecd540ef1749615ee.tar.gz -> frida-forks-libgee-69621d2c665b75c1e064abdecd540ef1749615ee.tar.gz
	https://github.com/frida/releng/archive/164a6a41179c38481e6afa4303abb92c9234ea2c.tar.gz -> frida-releng-164a6a41179c38481e6afa4303abb92c9234ea2c.tar.gz
	https://github.com/frida-forks/meson/archive/145667c57ed2649ddcc6fbb11b6008e0d451df1d.tar.gz -> frida-forks-meson-145667c57ed2649ddcc6fbb11b6008e0d451df1d.tar.gz
	https://github.com/python-poetry/tomlkit/archive/911cccd630965ff423316e25b4685ecf7df0ec0a.tar.gz -> python-poetry-tomlkit-911cccd630965ff423316e25b4685ecf7df0ec0a.tar.gz
"

# <directory inside the tree> <distfile>
_FRIDA_PINS=(
	"subprojects/efni frida-efni-72f90afcc1f7c663db4de934e9f7ab9d3f67d4b1.tar.gz"
	"subprojects/frida-gum frida-frida-gum-17.26.2.tar.gz"
	"subprojects/frida-gum/subprojects/capstone frida-forks-capstone-f919a03a5417e1c7ea3af7035225073437030ef2.tar.gz"
	"subprojects/frida-gum/subprojects/json-glib frida-forks-json-glib-0242c39f1f60f844c9df41e83434251b06609e82.tar.gz"
	"subprojects/frida-gum/subprojects/libdwarf frida-forks-libdwarf-9ac8cc22cab54d72cb355a44e85db716a7006f47.tar.gz"
	"subprojects/frida-gum/subprojects/libsoup frida-forks-libsoup-2537f36926436ef7ac7e2430c25755216ed54ca5.tar.gz"
	"subprojects/frida-gum/subprojects/libunwind frida-forks-libunwind-733d7d1c73f3512d2a50add2337157fa385a7e6e.tar.gz"
	"subprojects/frida-gum/subprojects/quickjs frida-forks-quickjs-6f3b5b4827d4c81af85627d66fce2ec3c8ab70d0.tar.gz"
	"subprojects/frida-gum/subprojects/tinycc frida-forks-tinycc-c0b84021e3e5c8359a469b1af2bf4abd83a7a26a.tar.gz"
	"subprojects/glib frida-forks-glib-f11db6352345ad21deb5f5783bb988bfca2a3d85.tar.gz"
	"subprojects/glib/subprojects/gvdb gnome-gvdb-2b42fc75f09dbe1cd1057580b5782b08f2dcb400.tar.gz"
	"subprojects/libbpf frida-forks-libbpf-9c4e176810717e27b6990a8722b252fc1967667f.tar.gz"
	"subprojects/libgee frida-forks-libgee-69621d2c665b75c1e064abdecd540ef1749615ee.tar.gz"
	"releng frida-releng-164a6a41179c38481e6afa4303abb92c9234ea2c.tar.gz"
	"releng/meson frida-forks-meson-145667c57ed2649ddcc6fbb11b6008e0d451df1d.tar.gz"
	"releng/tomlkit python-poetry-tomlkit-911cccd630965ff423316e25b4685ecf7df0ec0a.tar.gz"
)

LICENSE="wxWinLL-3.1 LGPL-2.1+ BSD MIT"
SLOT="0"
KEYWORDS="~amd64"

# The glib, json-glib, libsoup, libgee, libunwind and capstone copies are
# linked statically into the devkit, so only the libraries meson takes from
# the system remain.
DEPEND="
	app-arch/brotli
	app-arch/xz-utils
	dev-libs/elfutils
	dev-libs/libffi
	dev-libs/libpcre2
	dev-libs/openssl:=
	dev-db/sqlite
	net-libs/libpsl
	net-libs/nghttp2:=
	virtual/zlib:=
"
RDEPEND="${DEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	dev-lang/vala:0.58
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/libunwind-include-immintrin-for-shstk.patch
	"${FILESDIR}"/gum-pthread-from-ptr-integer-pthread_t.patch
	"${FILESDIR}"/libc-shim-stdio-streams-not-const.patch
)

S="${WORKDIR}/${PN}-${PV}"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_unpack() {
	unpack "${P}.tar.gz"

	local i dir dist
	for ((i = 0; i < ${#_FRIDA_PINS[@]}; i++)); do
		set -- ${_FRIDA_PINS[i]}
		dir=${S}/$1 dist=$2
		rm -rf "${dir}" || die
		mkdir -p "${dir}" || die
		tar -xzf "${DISTDIR}/${dist}" -C "${dir}" --strip-components=1 || die "unpacking ${dist}"
	done
}

src_configure() {
	# The devkit is an ar archive of every object in the tree, which cannot
	# hold LTO bitcode. LTO_SELF keeps a site-wide -flto out of CFLAGS.
	export LTO_SELF=1
	filter-lto

	export FRIDA_VERSION=${PV}
	export VALAC=${BROOT}/usr/bin/valac-0.58

	local emesonargs=(
		-Db_lto=false
		-Ddefault_library=static
		-Dcompiler_backend=disabled
		-Dfruity_backend=disabled
		-Ddroidy_backend=enabled
		-Dsimmy_backend=disabled
		-Dbarebone_backend=disabled
		-Dconnectivity=disabled
		-Dportal=disabled
		-Dgadget=disabled
		-Dinject=disabled
		-Dserver=disabled
		-Dcompat=disabled
		-Ddevkits=core
		-Dtests=disabled
		-Dfrida-gum:v8=disabled
		-Dfrida-gum:quickjs=enabled
		-Dfrida-gum:database=disabled
		-Dfrida-gum:gumpp=disabled
		-Dfrida-gum:tests=disabled
		-Dglib:introspection=disabled
		--force-fallback-for=glib-2.0,gobject-2.0,gio-2.0,gio-unix-2.0,gmodule-2.0,gthread-2.0,json-glib-1.0,gee-0.8,capstone
	)
	meson_src_configure
}

src_install() {
	# frida-python builds against this directory (FRIDA_CORE_DEVKIT).
	local dir=/usr/$(get_libdir)/${PN}/devkit
	insinto "${dir}"
	doins "${BUILD_DIR}"/src/devkit/{frida-core.h,libfrida-core.a}
}

