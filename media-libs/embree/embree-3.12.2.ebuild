# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake flag-o-matic toolchain-funcs

DESCRIPTION="Collection of high-performance ray tracing kernels"
HOMEPAGE="https://github.com/embree/embree"

if [[ ${PV} = *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/embree/embree.git"
	KEYWORDS=""
else
	SRC_URI="https://github.com/embree/embree/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="Apache-2.0"
SLOT="0"

IUSE="clang ispc raymask static-libs +tbb tutorial"

REQUIRED_USE="clang? ( !tutorial )"

RDEPEND="
	media-libs/glfw
	virtual/opengl
	ispc? ( dev-lang/ispc )
	tbb? ( dev-cpp/tbb )
	tutorial? (
		media-libs/libpng
		>=media-libs/openimageio-2.0:=
		virtual/jpeg:0
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	clang? ( sys-devel/clang )
"

DOCS=( CHANGELOG.md README.md readme.pdf )

#CMAKE_BUILD_TYPE=Release

src_prepare() {
	cmake_src_prepare

	# disable RPM package building
	sed -e 's|CPACK_RPM_PACKAGE_RELEASE 1|CPACK_RPM_PACKAGE_RELEASE 0|' \
		-i CMakeLists.txt || die
	# change -O3 settings for various compilers
	#sed -e 's|-O3|-O2|' -i "${S}"/common/cmake/{clang,gnu,intel,ispc}.cmake || die
}

src_configure() {
	if use clang; then
		export CC=clang
		export CXX=clang++
		strip-flags
		filter-flags "-frecord-gcc-switches"
		filter-ldflags "-Wl,--as-needed"
		filter-ldflags "-Wl,-O1"
		filter-ldflags "-Wl,--defsym=__gentoo_check_ldflags__=0"
	fi

# FIXME:
#	any option with a comment # default at the end of the line is
#	currently set to use default value. Some of them could probably
#	be turned into USE flags.
#
#	EMBREE_CURVE_SELF_INTERSECTION_AVOIDANCE_FACTOR: leave it at 2.0f for now
#		0.0f disables self intersection avoidance.
#
# The build currently only works with their own C{,XX}FLAGS,
# not respecting user flags.
#		-DEMBREE_IGNORE_CMAKE_CXX_FLAGS=OFF
	local mycmakeargs=(
		-DBUILD_TESTING:BOOL=OFF
#		-DCMAKE_C_COMPILER=$(tc-getCC)
#		-DCMAKE_CXX_COMPILER=$(tc-getCXX)
		-DCMAKE_SKIP_INSTALL_RPATH:BOOL=ON
		-DEMBREE_BACKFACE_CULLING=OFF			# default
		-DEMBREE_FILTER_FUNCTION=ON				# default
		-DEMBREE_GEOMETRY_CURVE=ON				# default
		-DEMBREE_GEOMETRY_GRID=ON				# default
		-DEMBREE_GEOMETRY_INSTANCE=ON			# default
		-DEMBREE_GEOMETRY_POINT=ON				# default
		-DEMBREE_GEOMETRY_QUAD=ON				# default
		-DEMBREE_GEOMETRY_SUBDIVISION=ON		# default
		-DEMBREE_GEOMETRY_TRIANGLE=ON			# default
		-DEMBREE_GEOMETRY_USER=ON				# default
		-DEMBREE_IGNORE_CMAKE_CXX_FLAGS=OFF
		-DEMBREE_IGNORE_INVALID_RAYS=OFF		# default
		-DEMBREE_ISPC_SUPPORT=$(usex ispc)
		-DEMBREE_RAY_MASK=$(usex raymask)
		-DEMBREE_RAY_PACKETS=ON					# default
		-DEMBREE_STACK_PROTECTOR=OFF			# default
		-DEMBREE_STATIC_LIB=$(usex static-libs)
		-DEMBREE_STAT_COUNTERS=OFF
		-DEMBREE_TASKING_SYSTEM:STRING=$(usex tbb "TBB" "INTERNAL")
		-DEMBREE_TUTORIALS=$(usex tutorial)
		-DEMBREE_MAX_ISA:STRING=AVX2
EMBREE_IGNORE_CMAKE_CXX_FLAGS
	)

	if use tutorial; then
		mycmakeargs+=(
			-DEMBREE_ISPC_ADDRESSING:STRING="64"
			-DEMBREE_TUTORIALS_LIBJPEG=ON
			-DEMBREE_TUTORIALS_LIBPNG=ON
			-DEMBREE_TUTORIALS_OPENIMAGEIO=ON
		)
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	doenvd "${FILESDIR}"/99${PN}
}
