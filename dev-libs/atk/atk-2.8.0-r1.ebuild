# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/atk/atk-2.8.0.ebuild,v 1.2 2013/07/24 21:46:03 eva Exp $

EAPI="5"
GCONF_DEBUG="no"

inherit gnome2 multilib-minimal

DESCRIPTION="GTK+ & GNOME Accessibility Toolkit"
HOMEPAGE="http://projects.gnome.org/accessibility/"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="+introspection nls test"

RDEPEND="
	>=dev-libs/glib-2.31.2:2[${MULTILIB_USEDEP}]
	introspection? ( >=dev-libs/gobject-introspection-0.6.7[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}
	>=dev-lang/perl-5
	dev-util/gtk-doc-am
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"

src_prepare() {
	gnome2_src_prepare

	if ! use test; then
		# don't waste time building tests (bug #226353)
		sed 's/^\(SUBDIRS =.*\)tests\(.*\)$/\1\2/' -i Makefile.am Makefile.in \
			|| die "sed failed"
	fi

	multilib_copy_sources
}

multilib_src_configure() {
	gnome2_src_configure $(use_enable introspection)
}
