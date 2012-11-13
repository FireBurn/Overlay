# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libxcb/libxcb-1.8.1.ebuild,v 1.9 2012/07/12 17:58:20 ranger Exp $

EAPI=4
ABI=x86
P="libxcb-1.8.1"
PN="libxcb"
S=${WORKDIR}/${P}

XORG_DOC=doc
inherit xorg-2

DESCRIPTION="X C-language Bindings library"
HOMEPAGE="http://xcb.freedesktop.org/"
EGIT_REPO_URI="git://anongit.freedesktop.org/git/xcb/libxcb"
[[ ${PV} != 9999* ]] && \
	SRC_URI="http://xcb.freedesktop.org/dist/${P}.tar.bz2"

KEYWORDS="~alpha amd64 arm hppa ~ia64 ~mips ppc ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="selinux"

RDEPEND="dev-libs/libpthread-stubs
	x11-libs/libXau
	x11-libs/libXdmcp"
DEPEND="${RDEPEND}
	app-emulation/emul-linux-x86-xlibs
	dev-lang/python[xml]
	dev-libs/libxslt
	>=x11-proto/xcb-proto-1.7-r1"

pkg_setup() {
	xorg-2_pkg_setup

        append-flags -m32

	XORG_CONFIGURE_OPTIONS=(
		$(use_enable doc build-docs)
		$(use_enable selinux)
		--enable-xinput
	)
}

src_install() {
        autotools-utils_src_install \
                docdir="${EPREFIX}/usr/share/doc/${PF}"
        rm -rf "${D}"/usr/share || die "Removing man files failed."
        rm -rf "${D}"/usr/include || die "Removing include files failed."
}

