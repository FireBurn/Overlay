# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-opengl/emul-linux-x86-opengl-20120127.ebuild,v 1.1 2012/01/27 18:10:28 pacho Exp $

EAPI="4"

inherit emul-linux-x86

LICENSE="BSD LGPL-2 MIT"

KEYWORDS="-* ~amd64 ~amd64-linux"

DEPEND="app-admin/eselect-opengl
	>=app-admin/eselect-mesa-0.0.9"
RDEPEND="media-libs/mesa
	media-libs/mesa-32bit"

emul-linux-x86_src_unpack() {
	cd "${S}"
}

emul-linux-x86_src_install() {
	cd "${S}"
}
