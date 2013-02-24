# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/udis86/udis86-1.7-r1.ebuild,v 1.4 2013/02/14 22:08:27 ago Exp $

EAPI=5
ABI="x86"

inherit autotools eutils flag-o-matic

DESCRIPTION="Disassembler library for the x86/-64 architecture sets."
HOMEPAGE="http://udis86.sourceforge.net/"
MY_PN="udis86"
MY_P=${MY_PN}-${PV}
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE="test"

DEPEND="test? (
		amd64? ( dev-lang/yasm )
		x86? ( dev-lang/yasm )
		x86-fbsd? ( dev-lang/yasm )
	)"
RDEPEND=""

S=${WORKDIR}/${MY_P}

src_prepare() {
	# Don't fail tests if dev-lang/yasm is not installed, bug #318805
	epatch "${FILESDIR}"/${MY_P}-yasm.patch
	eautoreconf
	append-flags -m32
}

src_configure() {
	econf \
		--docdir="/usr/share/doc/${PF}" \
		--disable-static \
		--enable-shared \
		--with-pic
}

src_install() {
	default
	find "${ED}"/usr -name '*.la' -delete
	rm -rf "${D}"/usr/share || die "Removing files failed."
	rm -rf "${D}"/usr/bin || die "Removing files failed."
	rm -rf "${D}"/usr/include || die "Removing files failed."
}
