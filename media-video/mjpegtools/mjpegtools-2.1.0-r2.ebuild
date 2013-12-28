# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/mjpegtools/mjpegtools-2.1.0-r1.ebuild,v 1.1 2013/11/30 14:47:03 billie Exp $

EAPI=5

inherit autotools eutils flag-o-matic toolchain-funcs multilib-minimal

DESCRIPTION="Tools for MJPEG video"
HOMEPAGE="http://mjpeg.sourceforge.net/"
SRC_URI="mirror://sourceforge/mjpeg/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="1"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd"
IUSE="dga dv gtk mmx png quicktime sdl sdlgfx static-libs v4l"
REQUIRED_USE="sdlgfx? ( sdl )"

RDEPEND="virtual/jpeg
	quicktime? ( media-libs/libquicktime[${MULTILIB_USEDEP}] )
	dv? ( >=media-libs/libdv-0.99[${MULTILIB_USEDEP}] )
	png? ( media-libs/libpng:0=[${MULTILIB_USEDEP}] )
	dga? ( x11-libs/libXxf86dga[${MULTILIB_USEDEP}] )
	gtk? ( x11-libs/gtk+:2[${MULTILIB_USEDEP}] )
	sdl? ( >=media-libs/libsdl-1.2.7-r3[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXt[${MULTILIB_USEDEP}]
		sdlgfx? ( media-libs/sdl-gfx[${MULTILIB_USEDEP}] )
	 )"

DEPEND="${RDEPEND}
	mmx? ( dev-lang/nasm )
	>=sys-apps/sed-4
	virtual/awk
	virtual/pkgconfig"

pkg_pretend() {
	if has_version ">=sys-kernel/linux-headers-2.6.38" && use v4l; then
		ewarn "Current versions of mjpegtools only support V4L1 which is not available"
		ewarn "for kernel versions 2.6.38 and above. V4L1 will be disabled."
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-pic.patch
	eautoreconf
	sed -i -e '/ARCHFLAGS=/s:=.*:=:' configure

	multilib_copy_sources
}

multilib_src_configure() {
	[[ $(gcc-major-version) -eq 3 ]] && append-flags -mno-sse2

	econf \
		--enable-compile-warnings \
		$(use_enable mmx simd-accel) \
		$(use_enable static-libs static) \
		--enable-largefile \
		$(use_with quicktime libquicktime) \
		$(use_with dv libdv) \
		$(use_with png libpng) \
		$(use_with dga) \
		$(use_with gtk) \
		$(use_with sdl libsdl) \
		$(use_with sdlgfx) \
		$(use_with v4l) \
		$(use_with sdl x)
}

multilib_src_install() {
	default

	dodoc mjpeg_howto.txt PLANS HINTS docs/FAQ.txt

	find "${D}" -name '*.la' -exec rm -rf '{}' '+' || die "la removal failed"
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		elog "mjpegtools installs user contributed scripts which require additional"
		elog "dependencies not pulled in by the installation."
		elog "These have to be installed manually."
		elog "Currently known extra dpendencies are: ffmpeg, mencoder from mplayer,"
		elog "parts of transcode, mpeg2dec from libmpeg2, sox, toolame, vcdimager, python."
	fi
}
