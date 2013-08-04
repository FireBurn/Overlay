# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sdl-sound/sdl-sound-1.0.3.ebuild,v 1.12 2013/04/30 21:13:39 hasufell Exp $

EAPI=5
inherit autotools eutils multilib-minimal

MY_P="${P/sdl-/SDL_}"
DESCRIPTION="A library that handles the decoding of sound file formats"
HOMEPAGE="http://icculus.org/SDL_sound/"
SRC_URI="http://icculus.org/SDL_sound/downloads/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~arm ppc ppc64 sparc x86 ~x86-fbsd ~x64-macos"
IUSE="flac mikmod modplug mp3 mpeg physfs speex static-libs vorbis"

RDEPEND=">=media-libs/libsdl-1.2[${MULTILIB_USEDEP}]
	flac? ( media-libs/flac[${MULTILIB_USEDEP}] )
	mikmod? ( >=media-libs/libmikmod-3.1.9[${MULTILIB_USEDEP}] )
	modplug? ( media-libs/libmodplug[${MULTILIB_USEDEP}] )
	vorbis? ( >=media-libs/libvorbis-1.0_beta4[${MULTILIB_USEDEP}] )
	speex? ( media-libs/speex media-libs/libogg[${MULTILIB_USEDEP}] )
	physfs? ( dev-games/physfs[${MULTILIB_USEDEP}] )
	mpeg? ( media-libs/smpeg[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${P}-{underlinking,automake-1.13}.patch
	mv configure.in configure.ac || die
	eautoreconf

	multilib_copy_sources
}

multilib_src_configure() {
	econf \
		--disable-dependency-tracking \
		--enable-midi \
		$(use_enable mpeg smpeg) \
		$(use_enable mp3 mpglib) \
		$(use_enable flac) \
		$(use_enable speex) \
		$(use_enable static-libs static) \
		$(use_enable mikmod) \
		$(use_enable modplug) \
		$(use_enable physfs) \
		$(use_enable vorbis ogg)
}

multilib_src_install() {
	emake DESTDIR="${D}" install || die
	dodoc CHANGELOG CREDITS README TODO
	if ! use static-libs ; then
		find "${D}" -type f -name '*.la' -exec rm {} + \
			|| die "la removal failed"
	fi
}
