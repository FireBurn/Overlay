# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-xlibs/emul-linux-x86-xlibs-20120127.ebuild,v 1.1 2012/01/27 18:15:13 pacho Exp $

EAPI=5

KEYWORDS="~amd64"
IUSE="opengl +development"

SLOT="0"

DEPEND=""

RDEPEND="app-emulation/emul-linux-x86-baselibs
"

PDEPEND="opengl? ( app-emulation/emul-linux-x86-opengl )"


SRC_URI=""
src_unpack(){
	mkdir "${S}"
}
src_install(){
	true
}
