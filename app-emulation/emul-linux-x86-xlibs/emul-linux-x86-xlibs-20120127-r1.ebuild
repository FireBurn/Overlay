# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-xlibs/emul-linux-x86-xlibs-20120127.ebuild,v 1.1 2012/01/27 18:15:13 pacho Exp $

EAPI="4"

inherit emul-linux-x86

LICENSE="FTL GPL-2 MIT"

KEYWORDS="-* ~amd64"
IUSE="opengl"

DEPEND=""
RDEPEND="~app-emulation/emul-linux-x86-baselibs-${PV}
	x11-libs/libX11
	opengl? ( app-emulation/emul-linux-x86-opengl )"
PDEPEND="x11-libs/libX11-32bit"

src_prepare() {
        emul-linux-x86_src_prepare
	rm -f "${S}/usr/lib32/libX11-xcb.so" || die
	rm -f "${S}/usr/lib32/libX11-xcb.so.1" || die
	rm -f "${S}/usr/lib32/libX11-xcb.so.1.0.0" || die
	rm -f "${S}/usr/lib32/libX11.so" || die
	rm -f "${S}/usr/lib32/libX11.so.6" || die
	rm -f "${S}/usr/lib32/libX11.so.6.3.0" || die
	rm -f "${S}/usr/lib32/pkgconfig/x11-xcb.pc" || die
	rm -f "${S}/usr/lib32/pkgconfig/x11.pc" || die
}
