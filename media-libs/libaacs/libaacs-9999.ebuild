# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

EAPI=5

inherit autotools git-r3

EGIT_REPO_URI="git://git.videolan.org/${PN}.git"

DESCRIPTION="Implementation of the Advanced Access Content System specification"
HOMEPAGE="http://www.videolan.org/developers/${PN}.html"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="static-libs examples"

DEPEND="sys-libs/glibc"
RDEPEND="${DEPEND}
"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf $(use_enable static-libs static) || die
}

src_compile() {
	emake || die

}

src_install() {
	emake DESTDIR="${D}" install || die

	dodoc README.txt KEYDB.cfg || die

	if use examples; then
		cd "${S}"/src/examples/.libs
		dobin libaacs_test parser_test || die
	fi
}
