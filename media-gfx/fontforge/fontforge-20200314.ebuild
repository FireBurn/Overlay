# Copyright 2004-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )

inherit python-single-r1 xdg ninja-utils cmake-utils

DESCRIPTION="postscript font editor and converter"
HOMEPAGE="http://fontforge.github.io/"
SRC_URI="https://github.com/fontforge/fontforge/releases/download/${PV}/fontforge-${PV}.tar.xz"

LICENSE="BSD GPL-3+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="cairo doc truetype-debugger gif gtk jpeg png +python readline test tiff svg unicode X"

RESTRICT="!test? ( test )"

REQUIRED_USE="
	cairo? ( png )
	gtk? ( cairo )
	python? ( ${PYTHON_REQUIRED_USE} )
	test? ( png python )
"

RDEPEND="
	dev-libs/glib
	dev-libs/libltdl:0
	dev-libs/libxml2:2=
	>=media-libs/freetype-2.3.7:2=
	cairo? (
		>=x11-libs/cairo-1.6:0=
		x11-libs/pango:0=
	)
	doc? ( dev-python/sphinx )
	gif? ( media-libs/giflib:0= )
	jpeg? ( virtual/jpeg:0 )
	png? ( media-libs/libpng:0= )
	tiff? ( media-libs/tiff:0= )
	truetype-debugger? ( >=media-libs/freetype-2.3.8:2[fontforge,-bindist(-)] )
	gtk? ( >=x11-libs/gtk+-3.10:3 )
	python? ( ${PYTHON_DEPS} )
	readline? ( sys-libs/readline:0= )
	unicode? ( media-libs/libuninameslist:0= )
	X? (
		x11-libs/libX11:0=
		x11-libs/libXi:0=
		>=x11-libs/pango-1.10:0=[X]
	)
	!media-gfx/pfaedit
"
DEPEND="${RDEPEND}
	X? ( x11-base/xorg-proto )
"
BDEPEND="
	sys-devel/gettext
	virtual/pkgconfig
"

# Needs keywording on many arches.
#	zeromq? (
#		>=net-libs/czmq-2.2.0:0=
#		>=net-libs/zeromq-4.0.4:0=
#	)

PATCHES=(
	"${FILESDIR}"/20170731-gethex-unaligned.patch
	"${FILESDIR}"/20200314-tilepath.patch
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_configure() {
	mycmakeargs=(
		-DENABLE_LIBSPIRO=0
		-DENABLE_DOCS=$(usex doc)
		-DENABLE_CODE_COVERAGE=0
		-DENABLE_DEBUG_RAW_POINTS=0
		-DENABLE_FONTFORGE_EXTRAS=0
		-DENABLE_GUI=$(usex gtk)
		-DENABLE_LIBGIF=$(usex gif)
		-DENABLE_LIBJPEG=$(usex jpeg)
		-DENABLE_LIBPNG=$(usex png)
		-DENABLE_LIBREADLINE=$(usex readline)
		-DENABLE_LIBTIFF=$(usex tiff)
		-DENABLE_LIBUNINAMESLIST=$(usex unicode)
		-DENABLE_MAINTAINER_TOOLS=0
		-DENABLE_NATIVE_SCRIPTING=1
		-DENABLE_PYTHON_EXTENSION=$(usex python)
		-DENABLE_PYTHON_SCRIPTING=$(usex python)
		-DENABLE_SANITIZER=none
		-DENABLE_TILE_PATH=1
		-DENABLE_WOFF2=0
		-DENABLE_WRITE_PFM=0
		-DENABLE_X11=$(usex X)
	)

	if use truetype-debugger ; then
		mycmakeargs+=( -DENABLE_FREETYPE_DEBUGGER="${EPREFIX}/usr/include/freetype2/internal4fontforge" )
	fi

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	#eninja DESTDIR="${D}" install
	docompress -x /usr/share/doc/${PF}/html
	einstalldocs
	find "${ED}" -name '*.la' -type f -delete || die
}
