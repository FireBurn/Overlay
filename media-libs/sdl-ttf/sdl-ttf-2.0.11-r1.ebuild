# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/sdl-ttf/sdl-ttf-2.0.11.ebuild,v 1.9 2012/06/08 19:38:07 mr_bones_ Exp $

EAPI=5
inherit autotools eutils multilib-minimal

MY_P="${P/sdl-/SDL_}"
DESCRIPTION="library that allows you to use TrueType fonts in SDL applications"
HOMEPAGE="http://www.libsdl.org/projects/SDL_ttf/"
SRC_URI="http://www.libsdl.org/projects/SDL_ttf/release/${MY_P}.tar.gz"

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="static-libs X"

DEPEND="X? ( x11-libs/libXt[${MULTILIB_USEDEP}] )
	media-libs/libsdl[${MULTILIB_USEDEP}]
	>=media-libs/freetype-2.3[${MULTILIB_USEDEP}]"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${P}-underlink.patch
	eautoreconf

	multilib_copy_sources
}

multilib_src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static) \
		$(use_with X x)
}

multilib_src_install() {
	emake DESTDIR="${D}" install || die
	dodoc CHANGES README
	use static-libs || prune_libtool_files --all
}
