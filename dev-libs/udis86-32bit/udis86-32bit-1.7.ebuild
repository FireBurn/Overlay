# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/udis86/udis86-1.7.ebuild,v 1.12 2010/11/11 17:30:39 hwoarang Exp $

EAPI=3
ABI="x86"
P="udis86-1.7"
PN="udis86"
S=${WORKDIR}/${P}
inherit autotools

DESCRIPTION="Disassembler library for the x86/-64 architecture sets."
HOMEPAGE="http://udis86.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ~hppa ppc ~ppc64 x86 ~x86-fbsd"
IUSE="pic test"

DEPEND="test? (
		amd64? ( dev-lang/yasm )
		x86? ( dev-lang/yasm )
		x86-fbsd? ( dev-lang/yasm )
	)"
RDEPEND=""

src_prepare() {
	P="udis86-1.7"
	PN="udis86"
	# Don't fail tests if dev-lang/yasm is not installed, bug #318805
	eautoreconf
	append-flags -m32
}

src_configure() {
	econf "$(use_with pic)"
}

src_install() {
	emake docdir="/usr/share/doc/${PF}/" DESTDIR="${D}" install || die "emake install failed"
	rm -rf "${D}"/usr/share || die "Removing files failed."
        rm -rf "${D}"/usr/bin || die "Removing files failed."
        rm -rf "${D}"/usr/include || die "Removing files failed."
}
