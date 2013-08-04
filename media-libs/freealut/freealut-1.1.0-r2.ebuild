# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/freealut/freealut-1.1.0-r2.ebuild,v 1.1 2013/07/21 18:08:04 ottxor Exp $

EAPI=5
inherit autotools multilib-minimal

DESCRIPTION="The OpenAL Utility Toolkit"
HOMEPAGE="http://www.openal.org/"
SRC_URI="http://connect.creativelabs.com/openal/Downloads/ALUT/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux"
IUSE=""

DEPEND="media-libs/openal[${MULTILIB_USEDEP}]"

src_prepare() {
	# Link against openal and pthread
	sed -i -e 's/libalut_la_LIBADD = .*/& -lopenal -lpthread/' src/Makefile.am
	AT_M4DIR="${S}/admin/autotools/m4" eautoreconf

	multilib_copy_sources
}

multilib_src_install() {
	default
	dohtml doc/*
}
