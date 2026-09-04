# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="C++ engine for simulating rigid bodies in 2D games"
HOMEPAGE="https://box2d.org/"
SRC_URI="https://github.com/erincatto/Box2D/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 ~loong ppc64 ~riscv x86"
IUSE="doc test"
RESTRICT="!test? ( test )"

DEPEND="test? ( dev-cpp/doctest )"
BDEPEND="doc? ( app-text/doxygen )"

PATCHES=(
	"${FILESDIR}/${P}-sandbox-error.patch" # bug 907072, downstream
	"${FILESDIR}/${P}-cmake-minreqver-3.10.patch" # bug 964480, on par w/ git master
)

src_prepare() {
	cmake_src_prepare

	# unbundle doctest
	rm unit-test/doctest.h || die
	ln -s "${ESYSROOT}"/usr/include/doctest/doctest.h unit-test/ || die
}

src_configure() {
	local mycmakeargs=(
		-DBOX2D_BUILD_TESTBED=OFF # bundled libs, broken anyway right now
		-DBOX2D_BUILD_UNIT_TESTS=$(usex test)
		-DBOX2D_BUILD_DOCS=$(usex doc)
	)
	cmake_src_configure
}

src_test() {
	"${BUILD_DIR}"/bin/unit_test || die
}

src_install() {
	cmake_src_install

	cat <<-EOF > "${T}"/box2d.pc
	prefix=${EPREFIX}/usr
	exec_prefix=\${prefix}
	libdir=\${exec_prefix}/$(get_libdir)
	includedir=\${prefix}/include

	Name: box2d
	Description: 2D physics engine
	Version: ${PV}
	Libs: -L\${libdir} -lbox2d
	Cflags: -I\${includedir} -I\${includedir}/box2d
	EOF

	insinto /usr/$(get_libdir)/pkgconfig
	doins "${T}"/box2d.pc
}
