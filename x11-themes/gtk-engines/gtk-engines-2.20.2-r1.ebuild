# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-themes/gtk-engines/gtk-engines-2.20.2.ebuild,v 1.13 2013/02/25 21:09:20 zmedico Exp $

EAPI="5"
GCONF_DEBUG="no"
GNOME_TARBALL_SUFFIX="bz2"

inherit eutils gnome2 multilib-minimal

DESCRIPTION="GTK+2 standard engines and themes"
HOMEPAGE="http://www.gtk.org/"

LICENSE="LGPL-2.1"
SLOT="2"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~x86-macos ~x64-solaris ~x86-solaris"
IUSE="accessibility lua"

RDEPEND=">=x11-libs/gtk+-2.12:2[${MULTILIB_USEDEP}]
	lua? ( dev-lang/lua )"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.31
	virtual/pkgconfig"

DOCS="AUTHORS ChangeLog NEWS README"

pkg_setup() {
	G2CONF="${G2CONF} --enable-animation $(use_enable lua) $(use_with lua system-lua)"
	use accessibility || G2CONF="${G2CONF} --disable-hc"
}

src_prepare() {
	# Patch from 2.21.x, fixes building with glib-2.32, bug #410455
	epatch "${FILESDIR}/${P}-glib.h.patch"
	gnome2_src_prepare

	multilib_copy_sources
}

multilib_src_install() {
	gnome2_src_install
	find "${ED}" -name "*.la" -delete || die
}
