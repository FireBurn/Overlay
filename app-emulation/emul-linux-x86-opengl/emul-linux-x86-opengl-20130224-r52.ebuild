# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-opengl/emul-linux-x86-opengl-20120127.ebuild,v 1.1 2012/01/27 18:10:28 pacho Exp $

EAPI=5

LICENSE=""

KEYWORDS="~amd64"
SLOT="0"
IUSE="+development"

DEPEND="app-admin/eselect-opengl
	>=app-admin/eselect-mesa-0.0.9"
RDEPEND="app-emulation/emul-linux-x86-xlibs"
PDEPEND="x11-libs/libdrm[abi_x86_32]
	media-libs/glew[abi_x86_32]
	virtual/glu[abi_x86_32]
	media-libs/mesa[abi_x86_32]"

src_unpack() {
	mkdir "${S}"
}

src_install() {
	true
}
