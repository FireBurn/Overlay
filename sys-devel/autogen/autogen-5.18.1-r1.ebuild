# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/autogen/autogen-5.18.1.ebuild,v 1.1 2013/12/02 10:18:43 radhermit Exp $

EAPI="4"

inherit eutils multilib-minimal

DESCRIPTION="Program and text file generation"
HOMEPAGE="http://www.gnu.org/software/autogen/"
SRC_URI="mirror://gnu/${PN}/rel${PV}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~arm-linux ~x86-linux ~x64-macos ~x86-macos"
IUSE="libopts static-libs"

RDEPEND=">=dev-scheme/guile-1.8[${MULTILIB_USEDEP}]
	dev-libs/libxml2[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"

src_prepare() {
	multilib_copy_sources
}


multilib_src_configure() {
	# suppress possibly incorrect -R flag
	export ag_cv_test_ldflags=

	econf $(use_enable static-libs static) \
		--with-libguile="${EPREFIX}/usr/$(get_libdir)"
}


multilib_src_install() {
	default
	prune_libtool_files

	if ! use libopts ; then
		rm "${ED}"/usr/share/autogen/libopts-*.tar.gz || die
	fi
}
