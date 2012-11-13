# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libxcb/libxcb-1.9.ebuild,v 1.1 2012/10/31 23:43:00 chithanh Exp $

EAPI=4
ABI=x86
P="libxcb-1.9"
PN="libxcb"
S=${WORKDIR}/${P}

XORG_DOC=doc
inherit xorg-2 flag-o-matic

DESCRIPTION="X C-language Bindings library"
HOMEPAGE="http://xcb.freedesktop.org/"
EGIT_REPO_URI="git://anongit.freedesktop.org/git/xcb/libxcb"
[[ ${PV} != 9999* ]] && \
	SRC_URI="http://xcb.freedesktop.org/dist/${P}.tar.bz2"

KEYWORDS="~amd64"
IUSE="selinux"

RDEPEND="dev-libs/libpthread-stubs
	x11-libs/libXau
	x11-libs/libXdmcp"
DEPEND="${RDEPEND}
	app-emulation/emul-linux-x86-xlibs
	dev-lang/python[xml]
	dev-libs/libxslt
	>=x11-proto/xcb-proto-1.7-r1"

PATCHES=(
	"${FILESDIR}"/${PN}-1.9-python-3-iteritems.patch
	"${FILESDIR}"/${PN}-1.9-python-3-exception.patch
)

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

