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
PDEPEND="x11-libs/libX11-32bit
	x11-libs/libxcb-32bit"

src_prepare() {
        emul-linux-x86_src_prepare
	rm -f "${S}/usr/lib32/libX11-xcb.so" || die
	rm -f "${S}/usr/lib32/libX11-xcb.so.1" || die
	rm -f "${S}/usr/lib32/libX11-xcb.so.1.0.0" || die
	rm -f "${S}/usr/lib32/libX11.so" || die
	rm -f "${S}/usr/lib32/libX11.so.6" || die
	rm -f "${S}/usr/lib32/libX11.so.6.3.0" || die
        rm -f "${S}/usr/lib32/libxcb-dpms.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-dri2.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-glx.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-randr.so.0.1.0" || die
        rm -f "${S}/usr/lib32/libxcb-record.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-render.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-res.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-screensaver.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-shape.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-shm.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-sync.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xevie.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xf86dri.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xfixes.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xinerama.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xinput.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xprint.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xtest.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xv.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-xvmc.so.0.0.0" || die
        rm -f "${S}/usr/lib32/libxcb-res.so" || die
        rm -f "${S}/usr/lib32/libxcb-screensaver.so" || die
        rm -f "${S}/usr/lib32/libxcb-shape.so" || die
        rm -f "${S}/usr/lib32/libxcb-shm.so" || die
        rm -f "${S}/usr/lib32/libxcb-sync.so" || die
        rm -f "${S}/usr/lib32/libxcb-xevie.so" || die
        rm -f "${S}/usr/lib32/libxcb-xf86dri.so" || die
        rm -f "${S}/usr/lib32/libxcb-xfixes.so" || die
        rm -f "${S}/usr/lib32/libxcb-xinerama.so" || die
        rm -f "${S}/usr/lib32/libxcb-xinput.so" || die
        rm -f "${S}/usr/lib32/libxcb-xprint.so" || die
        rm -f "${S}/usr/lib32/libxcb-xtest.so" || die
        rm -f "${S}/usr/lib32/libxcb-xv.so" || die
        rm -f "${S}/usr/lib32/libxcb-xvmc.so" || die
        rm -f "${S}/usr/lib32/libxcb.so.1.1.0" || die
        rm -f "${S}/usr/lib32/pkgconfig/x11-xcb.pc" || die
        rm -f "${S}/usr/lib32/pkgconfig/x11.pc" || die 
}
