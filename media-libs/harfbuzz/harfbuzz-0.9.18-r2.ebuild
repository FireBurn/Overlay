# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/harfbuzz/harfbuzz-0.9.18-r1.ebuild,v 1.3 2013/07/13 08:18:34 grobian Exp $

EAPI=5

EGIT_REPO_URI="git://anongit.freedesktop.org/harfbuzz"
[[ ${PV} == 9999 ]] && inherit git-2 autotools

inherit eutils libtool autotools multilib-minimal

DESCRIPTION="An OpenType text shaping engine"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/HarfBuzz"
[[ ${PV} == 9999 ]] || SRC_URI="http://www.freedesktop.org/software/${PN}/release/${P}.tar.bz2"

LICENSE="Old-MIT ISC icu"
SLOT="0/0.9.18" # 0.9.18 introduced the harfbuzz-icu split; bug #472416
[[ ${PV} == 9999 ]] || \
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~x86-macos ~x64-macos ~x64-solaris"
IUSE="+cairo +glib +graphite icu static-libs +truetype"

RDEPEND="
	cairo? ( x11-libs/cairo:=[${MULTILIB_USEDEP}] )
	glib? ( dev-libs/glib:2[${MULTILIB_USEDEP}] )
	graphite? ( media-gfx/graphite2:=[${MULTILIB_USEDEP}] )
	icu? ( dev-libs/icu:=[${MULTILIB_USEDEP}] )
	truetype? ( media-libs/freetype:2=[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}
	dev-util/ragel
	virtual/pkgconfig
"

src_prepare() {
	if [[ ${CHOST} == *-darwin* || ${CHOST} == *-solaris* ]] ; then
		# on Darwin/Solaris we need to link with g++, like automake defaults
		# to, but overridden by upstream because on Linux this is not
		# necessary, bug #449126
		sed -i \
			-e 's/\<LINK\>/CXXLINK/' \
			src/Makefile.am || die
		sed -i \
			-e '/libharfbuzz_la_LINK = /s/\<LINK\>/CXXLINK/' \
			src/Makefile.in || die
	fi

	[[ ${PV} == 9999 ]] && eautoreconf

	epatch "${FILESDIR}/${P}-ldadd.patch"
	eautoreconf

	multilib_copy_sources
}

multilib_src_configure() {
	econf \
		--without-coretext \
		--without-uniscribe \
		$(use_enable static-libs static) \
		$(use_with cairo) \
		$(use_with glib) \
		$(use_with graphite graphite2) \
		$(use_with icu) \
		$(use_with truetype freetype)

}

multilib_src_install() {
	default
	prune_libtool_files --modules
}
