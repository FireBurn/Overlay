# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-arch/snappy/snappy-1.1.2-r1.ebuild,v 1.2 2014/08/11 22:07:50 blueness Exp $

EAPI="5"

inherit eutils autotools-multilib

DESCRIPTION="A high-speed compression/decompression library by Google"
HOMEPAGE="https://code.google.com/p/snappy/"
# upstream uses google drive which has hash-based URLS
SRC_URI="http://dev.gentoo.org/~radhermit/dist/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux"
IUSE="static-libs"

src_prepare() {
	# Avoid automagic lzo and gzip by not checking for it
	sed -i '/^CHECK_EXT_COMPRESSION_LIB/d' configure.ac || die

	# don't install unwanted files
	sed -i 's/COPYING INSTALL//' Makefile.am || die

	autotools-multilib_src_prepare
}

multilib_src_configure() {
	ECONF_SOURCE=${S} \
	econf \
		--docdir='$(datarootdir)'/doc/${PF} \
		--without-gflags \
		--disable-gtest \
		$(use_enable static-libs static)
}

multilib_src_install_all() {
	prune_libtool_files
}
