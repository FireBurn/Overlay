# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-sdl/emul-linux-x86-sdl-20130224.ebuild,v 1.2 2013/03/16 15:23:36 pacho Exp $

EAPI=5
inherit emul-linux-x86

LICENSE="LGPL-2 LGPL-2.1 ZLIB"
KEYWORDS="-* amd64"
IUSE="abi_x86_32"

DEPEND=""
RDEPEND="~app-emulation/emul-linux-x86-xlibs-${PV}
	~app-emulation/emul-linux-x86-baselibs-${PV}
	~app-emulation/emul-linux-x86-soundlibs-${PV}
	~app-emulation/emul-linux-x86-medialibs-${PV}"
PDEPEND="abi_x86_32? (
	media-libs/libsdl:0[abi_x86_32(-)]
	media-libs/libsdl:2[abi_x86_32(-)]
	media-libs/sdl-image:0[abi_x86_32(-)]
	media-libs/sdl-image:2[abi_x86_32(-)]
	media-libs/sdl-mixer:0[abi_x86_32(-)]
	media-libs/sdl-net:0[abi_x86_32(-)]
	media-libs/sdl-sound:0[abi_x86_32(-)]
	media-libs/sdl-ttf:0[abi_x86_32(-)]
	media-libs/openal[abi_x86_32(-)]
	media-libs/freealut[abi_x86_32(-)]
	)"

src_prepare() {
	emul-linux-x86_src_prepare

	# Remove migrated stuff.
	use abi_x86_32 && rm -f $(cat "${FILESDIR}/remove-native")
}

src_install() {
	if use abi_x86_32; then
		einfo "Nothing to install"
	else
		default
	fi
}
