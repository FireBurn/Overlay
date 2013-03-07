# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
ABI=x86

inherit cmake-utils mercurial versionator flag-o-matic

REV="$(get_version_component_range 4)"

DESCRIPTION="Simple Direct Media Layer"
HOMEPAGE="http://www.libsdl.org/"
#SRC_URI=""
EHG_REPO_URI="http://hg.libsdl.org/SDL/"
EHG_REVISION="${REV/pre/}"
EHG_PROJECT="libsdl"

LICENSE="ZLIB"
SLOT="2"
KEYWORDS="~amd64 ~x86"
IUSE="3dnow alsa altivec +asm aqua fusionsound gles mmx nas opengl oss pulseaudio sse sse2 static-libs +threads tslib +video X xinerama xscreensaver"

#FIXME: Replace "gles" deps with "virtual/opengles", after hitting Portage.
RDEPEND="
	nas? (
		media-libs/nas
		app-emulation/emul-linux-x86-xlibs
	)
	X? (
		app-emulation/emul-linux-x86-xlibs
	)
	xinerama? ( app-emulation/emul-linux-x86-xlibs )
	xscreensaver? ( app-emulation/emul-linux-x86-xlibs )
	alsa? ( app-emulation/emul-linux-x86-soundlibs )
	fusionsound? ( >=media-libs/FusionSound-1.1.1 )
	pulseaudio? ( app-emulation/emul-linux-x86-soundlibs )
	gles? ( || ( media-libs/mesa-32bit[gles2] app-emulation/emul-linux-x86-opengl ) )
	opengl? ( app-emulation/emul-linux-x86-opengl )
	tslib? ( x11-libs/tslib )
"

DEPEND="${RDEPEND}
	nas? (
		x11-proto/xextproto
		x11-proto/xproto
	)
	X? (
		x11-proto/inputproto
		x11-proto/xextproto
		x11-proto/xf86vidmodeproto
		x11-proto/xproto
		x11-proto/randrproto
		x11-proto/renderproto
	)
	xinerama? ( x11-proto/xineramaproto )
	xscreensaver? ( x11-proto/scrnsaverproto )
"

DOCS=( BUGS CREDITS README README.HG README-SDL.txt TODO WhatsNew )

pkg_setup() {
	append-flags -m32
	append-ldflags -m32
}

src_configure() {
	mycmakeargs=(
		# Disable assertion tests.
		-DASSERTIONS=disabled
		# Avoid hard-coding RPATH entries into dynamically linked SDL libraries.
		-DRPATH=NO
		# Disable obsolete and/or inapplicable libraries.
		-DARTS=NO
		-DESD=NO
		$(cmake-utils_use 3dnow 3DNOW)
		$(cmake-utils_use alsa ALSA)
		$(cmake-utils_use altivec ALTIVEC)
		$(cmake-utils_use asm ASSEMBLY)
		$(cmake-utils_use aqua VIDEO_COCOA)
		$(cmake-utils_use fusionsound FUSIONSOUND)
		$(cmake-utils_use gles VIDEO_OPENGLES)
		$(cmake-utils_use mmx MMX)
		$(cmake-utils_use nas NAS)
		$(cmake-utils_use opengl VIDEO_OPENGL)
		$(cmake-utils_use oss OSS)
		$(cmake-utils_use pulseaudio PULSEAUDIO)
		$(cmake-utils_use threads PTHREADS)
		$(cmake-utils_use sse SSE)
		$(cmake-utils_use sse SSEMATH)
		$(cmake-utils_use sse2 SSE2)
		$(cmake-utils_use static-libs SDL_STATIC)
		$(cmake-utils_use tslib INPUT_TSLIB)
		$(cmake-utils_use video VIDEO_DUMMY)
		$(cmake-utils_use X VIDEO_X11)
		$(cmake-utils_use X VIDEO_X11_XCURSOR)
		$(cmake-utils_use X VIDEO_X11_XINERAMA)
		$(cmake-utils_use X VIDEO_X11_XINPUT)
		$(cmake-utils_use X VIDEO_X11_XRANDR)
		$(cmake-utils_use xscreensaver VIDEO_X11_XSCRNSAVER)
		$(cmake-utils_use X VIDEO_X11_XVM)
		#$(cmake-utils_use joystick SDL_JOYSTICK)
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	rm -rf "${ED}"/usr/include || die "Removing includes failed."
	rm -rf "${ED}"/usr/bin || die "Removing binaries failed."
	pushd "${ED}"/usr/$(get_libdir)/ || die "pushd failed"
		ln -s libSDL2.so.2.0.0 libSDL2-2.0.so.0 || die "Creating symlink failed"
	popd
}
