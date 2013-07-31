# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-opengl/emul-linux-x86-opengl-20120127.ebuild,v 1.1 2012/01/27 18:10:28 pacho Exp $

EAPI=5

inherit emul-linux-x86

LICENSE="BSD LGPL-2 MIT"

KEYWORDS="~amd64"

DEPEND="!x11-libs/libdrm-32bit
        !media-libs/glew-32bit
        !media-libs/mesa-32bit
        !=media-libs/glu-9999-r50
	app-admin/eselect-opengl
	>=app-admin/eselect-mesa-0.0.9"
RDEPEND="!=app-emulation/emul-linux-x86-xlibs-20130224-r50
	!=app-emulation/emul-linux-x86-xlibs-20130224-r51
	>=app-emulation/emul-linux-x86-xlibs-20130224-r1"
PDEPEND="x11-libs/libdrm[abi_x86_32]
	media-libs/glew[abi_x86_32]
	virtual/glu[abi_x86_32]
	media-libs/mesa[abi_x86_32]"

emul-linux-x86_src_unpack() {
	cd "${S}"
}

emul-linux-x86_src_install() {
	cd "${S}"
}
