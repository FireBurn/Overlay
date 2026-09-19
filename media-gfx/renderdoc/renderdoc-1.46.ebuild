# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# The swig fork is required for compatibility with both provided and
# 3rd-party Python scripts.  Required patch was sent to upstream in
# 2014: https://github.com/swig/swig/pull/251
MY_SWIG_VER=7
MY_SWIG=swig-${PN}-${MY_SWIG_VER}

AUTOTOOLS_AUTO_DEPEND="no"
DOCS_BUILDER="sphinx"
DOCS_DIR="docs"
PYTHON_COMPAT=( python3_{11..14} )
inherit autotools cmake flag-o-matic optfeature python-single-r1 docs qt-utils
inherit toolchain-funcs verify-sig xdg

DESCRIPTION="A stand-alone graphics debugging tool"
HOMEPAGE="https://renderdoc.org https://github.com/baldurk/renderdoc"
SRC_URI="
	https://github.com/baldurk/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	qt6? ( https://github.com/baldurk/swig/archive/${PN}-modified-${MY_SWIG_VER}.tar.gz -> ${MY_SWIG}.tar.gz )
	verify-sig? ( https://github.com/baldurk/renderdoc/releases/download/v${PV}/v${PV}.tar.gz.asc -> ${P}.tar.gz.asc )
"

# renderdoc: MIT
#   + cmdline: BSD (not compatible with upstream lib)
#   + farm fresh icons: CC-BY-3.0
#   + half: MIT (not compatible with system dev-libs/half)
#   + include-bin ZLIB (upstream doesn't exist anymore, maintained in tree)
#   + md5: public-domain
#   + plthook: BSD-2
#   + pugixml: MIT
#   + radeon gpu analyzer: MIT
#   + source code pro: OFL-1.1
#   + stb: public-domain
#   + tinyfiledialogs: ZLIB
#   + glslang: BSD
#   + docs? ( sphinx.paramlinks: MIT )
# swig: GPL-3+ BSD BSD-2
LICENSE="BSD BSD-2 CC-BY-3.0 GPL-3+ MIT OFL-1.1 public-domain ZLIB"
SLOT="0"
KEYWORDS="amd64"
IUSE="qt6 wayland"
REQUIRED_USE="doc? ( qt6 ) qt6? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	app-arch/lz4:=
	app-arch/zstd:=
	dev-libs/miniz:=
	x11-libs/libX11
	x11-libs/libxcb:=
	x11-libs/xcb-util-keysyms
	virtual/opengl
	wayland? ( dev-libs/wayland )
	qt6? (
		${PYTHON_DEPS}
		dev-qt/qtbase[gui,network,widgets]
		dev-qt/qt5compat
	)
"
DEPEND="${RDEPEND}"
# qtcore provides qmake, which is required to build the qrenderdoc gui.
BDEPEND="
	x11-base/xorg-proto
	virtual/pkgconfig
	qt6? (
		${AUTOTOOLS_DEPEND}
		${PYTHON_DEPS}
		dev-libs/libpcre
		dev-qt/qtbase
		app-alternatives/yacc
	)
	verify-sig? ( sec-keys/openpgp-keys-baldurkarlsson )
"

PATCHES=(
	# The analytics seem very reasonable, and even without this patch
	# they are NOT sent before the user accepts.  But default the
	# selection to off, just in case.
	"${FILESDIR}"/${PN}-1.46-analytics-off.patch

	# Only search for PySide2 if pyside2 USE flag is set.
	# Bug #833627
	"${FILESDIR}"/${PN}-1.18-conditional-pyside.patch

	# Pass CXXFLAGS and LDFLAGS through to qmake when qrenderdoc is
	# built.
	"${FILESDIR}"/${PN}-1.18-system-flags.patch

	# Needed to prevent sandbox violations during build.
	"${FILESDIR}"/${PN}-1.27-env-home.patch

	"${FILESDIR}"/${PN}-1.30-r1-system-compress.patch

	# Bug #925578
	"${FILESDIR}"/${PN}-1.31-lld.patch

	# qrenderdoc only supports Qt5 upstream
	"${FILESDIR}"/${PN}-1.46-qt6.patch

	# keep the GUI on xcb even with wayland capture built in
	"${FILESDIR}"/${PN}-1.46-wayland-gui-xcb.patch
)

DOCS=( util/LINUX_DIST_README )

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/baldurkarlsson.gpg

pkg_setup() {
	use qt6 && python-single-r1_pkg_setup
}

src_unpack() {
	if use verify-sig; then
	   verify-sig_verify_detached "${DISTDIR}"/${P}.tar.gz{,.asc}
	fi

	# Do not unpack the swig sources here.  CMake will do that if
	# required.
	unpack ${P}.tar.gz
}

src_prepare() {
	cmake_src_prepare

	# Remove the calls to install the documentation files.  Instead,
	# install them with einstalldocs.
	sed -i '/share\/doc\/renderdoc/d' \
		"${S}"/CMakeLists.txt "${S}"/qrenderdoc/CMakeLists.txt \
		|| die 'sed remove doc install failed'

	# Assumes that the build directory is "${S}"/build, which it is not.
	sed -i "s|../build/lib|${BUILD_DIR}/lib|" \
		"${S}"/docs/conf.py \
		|| die 'sed patch doc sys.path failed'

	# Bug #836235
	sed -i '/#include <stdarg/i #include <time.h>' \
		"${S}"/renderdoc/os/os_specific.h \
		|| die 'sed include time.h failed'
}

src_configure() {
	local mycmakeargs=(
		# Build system does not know that this is a tagged release, as
		# we just have the tarball and not the git repository.
		-DBUILD_VERSION_STABLE=ON

		-DENABLE_EGL=ON
		-DENABLE_GL=ON
		-DENABLE_GLES=ON
		-DENABLE_PYRENDERDOC=$(usex qt6)
		-DENABLE_QRENDERDOC=$(usex qt6)
		-DENABLE_VULKAN=ON

		# unsupported upstream; needed to capture Wayland clients
		-DENABLE_UNSUPPORTED_EXPERIMENTAL_POSSIBLY_BROKEN_WAYLAND=$(usex wayland)

		-DENABLE_XCB=ON
		-DENABLE_XLIB=ON

		# renderdoc_capture.json is installed here
		-DVULKAN_LAYER_FOLDER="${EPREFIX}"/etc/vulkan/implicit_layer.d
	)

	# qmake's default mkspec is whatever Qt was built with, not what we use
	use qt6 && export QMAKESPEC=$(tc-is-clang && echo linux-clang || echo linux-g++)

	use qt6 && mycmakeargs+=(
		-DPython3_EXECUTABLE="${PYTHON}"
		-DRENDERDOC_SWIG_PACKAGE="${DISTDIR}"/${MY_SWIG}.tar.gz

		-DQMAKE_QT5_COMMAND="$(qt_get_bindir 6)"/qmake

		# the PySide bindings are PySide2, which is Qt5 only
		-DQRENDERDOC_ENABLE_PYSIDE2=OFF
	)

	# Lots of type mismatch issues.
	filter-lto

	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	docs_compile
}

pkg_postinst() {
	xdg_pkg_postinst
	optfeature "android remote contexts" dev-util/android-tools
	optfeature "vulkan contexts" media-libs/vulkan-loader
}
