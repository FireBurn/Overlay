# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-xlibs/emul-linux-x86-xlibs-20120127.ebuild,v 1.1 2012/01/27 18:15:13 pacho Exp $

EAPI=5

inherit emul-linux-x86

LICENSE="FTL GPL-2 MIT"

KEYWORDS="~amd64"
IUSE="opengl"

DEPEND=""

RDEPEND="!=app-emulation/emul-linux-x86-opengl-20130224-r50
	~app-emulation/emul-linux-x86-baselibs-${PV}
	x11-libs/libX11
	!x11-libs/libX11-32bit
	!x11-libs/libxcb-32bit
"

PDEPEND="opengl? ( app-emulation/emul-linux-x86-opengl )"
