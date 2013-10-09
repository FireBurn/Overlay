# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-gstplugins/emul-linux-x86-gstplugins-20130224.ebuild,v 1.2 2013/03/16 15:20:08 pacho Exp $

EAPI=5
inherit emul-linux-x86

LICENSE="GPL-2 LGPL-2 LGPL-2.1"
KEYWORDS="-* amd64"
IUSE="abi_x86_32"

DEPEND=""
RDEPEND="~app-emulation/emul-linux-x86-baselibs-${PV}
	~app-emulation/emul-linux-x86-db-${PV}
	~app-emulation/emul-linux-x86-gtklibs-${PV}
	~app-emulation/emul-linux-x86-medialibs-${PV}
	~app-emulation/emul-linux-x86-soundlibs-${PV}
	media-libs/gst-plugins-good:0.10[abi_x86_32(-)]
	media-libs/gst-plugins-bad:0.10[abi_x86_32(-)]
	media-libs/gst-plugins-ugly:0.10[abi_x86_32(-)]
"

src_install() {
	use abi_x86_32 || emul-linux-x86_src_install
}
