# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/wayland/wayland-1.2.0.ebuild,v 1.1 2013/07/13 13:53:38 chithanh Exp $

EAPI=5

if [[ ${PV} = 9999* ]]; then
	EGIT_REPO_URI="git://anongit.freedesktop.org/git/${PN}/${PN}"
	GIT_ECLASS="git-2"
	EXPERIMENTAL="true"
fi

inherit autotools eutils toolchain-funcs $GIT_ECLASS multilib-minimal

DESCRIPTION="Wayland protocol libraries"
HOMEPAGE="http://wayland.freedesktop.org/"

if [[ $PV = 9999* ]]; then
	SRC_URI="${SRC_PATCHES}"
	KEYWORDS=""
else
	SRC_URI="http://wayland.freedesktop.org/releases/${P}.tar.xz"
	KEYWORDS="~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~x86"
fi

LICENSE="MIT"
SLOT="0"
IUSE="doc static-libs"

RDEPEND="dev-libs/expat[${MULTILIB_USEDEP}]
	virtual/libffi[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

src_prepare() {
	epatch "${FILESDIR}"/0001-Add-option-to-not-install-wayland-scanner.patch
	epatch "${FILESDIR}"/0002-Add-option-to-configure
	if [[ ${PV} = 9999* ]]; then
		eautoreconf
	fi
	multilib_copy_sources
}

multilib_src_configure() {
	myconf="$(use_enable static-libs static) \
			$(use_enable doc documentation)"
	if tc-is-cross-compiler ; then
		myconf+=" --disable-scanner"
	fi
	if [[ ${ABI} != ${DEFAULT_ABI} ]] ; then
		myconf+=" --disable-scanner-install"
	fi
	econf ${myconf}
}
