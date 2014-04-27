# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-sdl/emul-linux-x86-sdl-20140406-r1.ebuild,v 1.1 2014/04/18 22:18:46 mgorny Exp $

EAPI=5
inherit emul-linux-x86

LICENSE="LGPL-2 LGPL-2.1 ZLIB"
KEYWORDS="-* ~amd64"
IUSE="abi_x86_32"

DEPEND=""
RDEPEND="~app-emulation/emul-linux-x86-xlibs-${PV}
	~app-emulation/emul-linux-x86-baselibs-${PV}
	~app-emulation/emul-linux-x86-soundlibs-${PV}
	~app-emulation/emul-linux-x86-medialibs-${PV}
	abi_x86_32? (
		>=media-libs/openal-1.15.1-r1[abi_x86_32(-)]
		>=media-libs/freealut-1.1.0-r3[abi_x86_32(-)]
		>=media-libs/libsdl-1.2.15-r5[abi_x86_32(-)]
		>=media-libs/sdl-gfx-2.0.24-r1[abi_x86_32(-)]
		>=media-libs/sdl-image-1.2.12-r1[abi_x86_32(-)]
		>=media-libs/sdl-net-1.2.8-r1[abi_x86_32(-)]
		>=media-libs/sdl-sound-1.0.3-r1[abi_x86_32(-)]
		>=media-libs/sdl-ttf-2.0.11-r1[abi_x86_32(-)]
		>=media-libs/smpeg-0.4.4-r10[abi_x86_32(-)]
		media-libs/libsdl2[abi_x86_32(-)]
		media-libs/sdl-image:2[abi_x86_32(-)]
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
