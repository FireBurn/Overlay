# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libmng/libmng-1.0.10-r1.ebuild,v 1.12 2013/08/27 14:56:02 kensington Exp $

EAPI=5
inherit autotools multilib-minimal

DESCRIPTION="Multiple Image Networkgraphics lib (animated png's)"
HOMEPAGE="http://www.libmng.com/"
SRC_URI="mirror://sourceforge/libmng/${P}.tar.gz"

LICENSE="libmng"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="lcms static-libs"

RDEPEND="virtual/jpeg:0[${MULTILIB_USEDEP}]
	>=sys-libs/zlib-1.1.4[${MULTILIB_USEDEP}]
	lcms? ( =media-libs/lcms-1*[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}"

src_prepare() {
	ln -s makefiles/configure.in .
	ln -s makefiles/Makefile.am .
	sed -i '/^AM_C_PROTOTYPES$/d' configure.in || die #420223

	eautoreconf

	multilib_copy_sources
}

multilib_src_configure() {
	econf \
		--disable-dependency-tracking \
		$(use_enable static-libs static) \
		--with-jpeg \
		$(use_with lcms)
}

multilib_src_install() {
	emake DESTDIR="${D}" install || die

	use static-libs || find "${ED}" -name '*.la' -exec rm -f {} +

	dodoc CHANGES README*
	dodoc doc/doc.readme doc/libmng.txt
	doman doc/man/*
}
