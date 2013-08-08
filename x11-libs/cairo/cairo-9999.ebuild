# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/cairo/cairo-9999.ebuild,v 1.30 2013/04/09 22:05:38 ssuominen Exp $

EAPI=5

inherit eutils flag-o-matic autotools multilib-minimal

if [[ ${PV} == *9999* ]]; then
	inherit git-2
	EGIT_REPO_URI="git://anongit.freedesktop.org/git/cairo"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="http://cairographics.org/releases/${P}.tar.xz"
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
fi

DESCRIPTION="A vector graphics library with cross-device output support"
HOMEPAGE="http://cairographics.org/"
LICENSE="|| ( LGPL-2.1 MPL-1.1 )"
SLOT="0"
IUSE="X aqua debug directfb doc drm gallium +glib legacy-drivers opengl openvg qt4 static-libs +svg xcb"

# Test causes a circular depend on gtk+... since gtk+ needs cairo but test needs gtk+ so we need to block it
RESTRICT="test"

RDEPEND="media-libs/fontconfig[${MULTILIB_USEDEP}]
	media-libs/freetype:2[${MULTILIB_USEDEP}]
	media-libs/libpng:0=[${MULTILIB_USEDEP}]
	sys-libs/zlib[${MULTILIB_USEDEP}]
	>=x11-libs/pixman-0.22.0[${MULTILIB_USEDEP}]
	directfb? ( dev-libs/DirectFB[${MULTILIB_USEDEP}] )
	glib? ( >=dev-libs/glib-2.28.6:2[${MULTILIB_USEDEP}] )
	opengl? ( || ( media-libs/mesa[egl,${MULTILIB_USEDEP}] media-libs/opengl-apple ) )
	openvg? ( media-libs/mesa[openvg,${MULTILIB_USEDEP}] )
	qt4? ( >=dev-qt/qtgui-4.8:4[${MULTILIB_USEDEP}] )
	X? (
		>=x11-libs/libXrender-0.6[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		drm? (
			>=virtual/udev-136[${MULTILIB_USEDEP}]
			gallium? ( media-libs/mesa[gallium,${MULTILIB_USEDEP}] )
		)
	)
	xcb? (
		x11-libs/libxcb[${MULTILIB_USEDEP}]
		x11-libs/xcb-util[${MULTILIB_USEDEP}]
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	>=sys-devel/libtool-2
	doc? (
		>=dev-util/gtk-doc-1.6
		~app-text/docbook-xml-dtd-4.2
	)
	X? (
		x11-proto/renderproto
		drm? (
			x11-proto/xproto
			>=x11-proto/xextproto-7.1
		)
	)"

# drm module requires X
# for gallium we need to enable drm
REQUIRED_USE="
	drm? ( X )
	gallium? ( drm )
"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.8.8-interix.patch
	use legacy-drivers && epatch "${FILESDIR}"/${PN}-1.10.0-buggy_gradients.patch
	epatch "${FILESDIR}"/${PN}-respect-fontconfig.patch
	epatch_user

	# Slightly messed build system YAY
	if [[ ${PV} == *9999* ]]; then
		touch boilerplate/Makefile.am.features
		touch src/Makefile.am.features
		touch ChangeLog
	fi

	# We need to run elibtoolize to ensure correct so versioning on FreeBSD
	# upgraded to an eautoreconf for the above interix patch.
	eautoreconf

	multilib_copy_sources
}

multilib_src_configure() {
	local myopts

	# SuperH doesn't have native atomics yet
	use sh && myopts+=" --disable-atomic"

	[[ ${CHOST} == *-interix* ]] && append-flags -D_REENTRANT
	# http://bugs.freedesktop.org/show_bug.cgi?id=15463
	[[ ${CHOST} == *-solaris* ]] && append-flags -D_POSIX_PTHREAD_SEMANTICS

	#gets rid of fbmmx.c inlining warnings
	append-flags -finline-limit=1200

	use X && myopts+=" --enable-tee=yes"

	use elibc_FreeBSD && myopts+=" --disable-symbol-lookup"

	# --disable-xcb-lib:
	#	do not override good xlib backed by hardforcing rendering over xcb
	# --disable-valgrind:
	#   valgrind code is busted as per upstream
	econf \
		--disable-dependency-tracking \
		$(use_with X x) \
		$(use_enable X xlib) \
		$(use_enable X xlib-xrender) \
		$(use_enable aqua quartz) \
		$(use_enable aqua quartz-image) \
		$(use_enable debug test-surfaces) \
		$(use_enable directfb) \
		$(use_enable glib gobject) \
		$(use_enable doc gtk-doc) \
		$(use_enable openvg vg) \
		$(use_enable opengl gl) \
		$(use_enable qt4 qt) \
		$(use_enable static-libs static) \
		$(use_enable svg) \
		$(use_enable xcb) \
		$(use_enable xcb xcb-shm) \
		$(use_enable drm) \
		$(use_enable gallium) \
		--enable-ft \
		--enable-pdf \
		--enable-png \
		--enable-ps \
		--disable-xlib-xcb \
		--disable-valgrind \
		${myopts}
}

multilib_src_install() {
	# parallel make install fails
	emake -j1 DESTDIR="${D}" install
	find "${ED}" -name '*.la' -exec rm -f {} +
	dodoc AUTHORS ChangeLog NEWS README
}
