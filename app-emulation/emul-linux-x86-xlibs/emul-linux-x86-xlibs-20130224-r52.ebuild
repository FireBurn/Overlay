# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-xlibs/emul-linux-x86-xlibs-20120127.ebuild,v 1.1 2012/01/27 18:15:13 pacho Exp $

EAPI=5

KEYWORDS="~amd64"
IUSE="opengl +development"

SLOT="0"

DEPEND=""

RDEPEND="app-emulation/emul-linux-x86-baselibs
dev-libs/libpthread-stubs[abi_x86_32]
dev-libs/wayland[abi_x86_32]
media-libs/fontconfig[abi_x86_32]
media-libs/freetype[abi_x86_32]
x11-drivers/ati-drivers disable-watermark
x11-drivers/xf86-video-ati glamor
x11-libs/libICE[abi_x86_32]
x11-libs/libSM[abi_x86_32]
x11-libs/libX11[abi_x86_32]
x11-libs/libXScrnSaver[abi_x86_32]
x11-libs/libXau[abi_x86_32]
x11-libs/libXaw[abi_x86_32]
x11-libs/libXcomposite[abi_x86_32]
x11-libs/libXcursor[abi_x86_32]
x11-libs/libXdamage[abi_x86_32]
x11-libs/libXdmcp[abi_x86_32]
x11-libs/libXext[abi_x86_32]
x11-libs/libXfixes[abi_x86_32]
x11-libs/libXft[abi_x86_32]
x11-libs/libXi[abi_x86_32]
x11-libs/libXinerama[abi_x86_32]
x11-libs/libXmu[abi_x86_32]
x11-libs/libXp[abi_x86_32]
x11-libs/libXpm[abi_x86_32]
x11-libs/libXrandr[abi_x86_32]
x11-libs/libXrender[abi_x86_32]
x11-libs/libXt[abi_x86_32]
x11-libs/libXtst[abi_x86_32]
x11-libs/libXvMC[abi_x86_32]
x11-libs/libXv[abi_x86_32]
x11-libs/libXxf86dga[abi_x86_32]
x11-libs/libXxf86vm[abi_x86_32]
x11-libs/libdrm[abi_x86_32]
x11-libs/libpciaccess[abi_x86_32]
x11-libs/libvdpau[abi_x86_32]
x11-libs/libxcb[abi_x86_32]
x11-proto/compositeproto[abi_x86_32]
x11-proto/damageproto[abi_x86_32]
x11-proto/dri2proto[abi_x86_32]
x11-proto/fixesproto[abi_x86_32]
x11-proto/glproto[abi_x86_32]
x11-proto/inputproto[abi_x86_32]
x11-proto/kbproto[abi_x86_32]
x11-proto/printproto[abi_x86_32]
x11-proto/randrproto[abi_x86_32]
x11-proto/recordproto[abi_x86_32]
x11-proto/renderproto[abi_x86_32]
x11-proto/scrnsaverproto[abi_x86_32]
x11-proto/videoproto[abi_x86_32]
x11-proto/xcb-proto[abi_x86_32]
x11-proto/xcb[abi_x86_32]
x11-proto/xextproto[abi_x86_32]
x11-proto/xf86bigfontproto[abi_x86_32]
x11-proto/xf86dgaproto[abi_x86_32]
x11-proto/xf86driproto[abi_x86_32]
x11-proto/xf86vidmodeproto[abi_x86_32]
x11-proto/xineramaproto[abi_x86_32]
x11-proto/xproto[abi_x86_32]
"

PDEPEND="opengl? ( app-emulation/emul-linux-x86-opengl )"


SRC_URI=""
src_unpack(){
	mkdir "${S}"
}
src_install(){
	true
}
