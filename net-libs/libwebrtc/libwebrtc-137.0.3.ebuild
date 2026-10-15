# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit edo python-any-r1 toolchain-funcs

DESCRIPTION="WebRTC static library for livekit and Zed, built with clang"
HOMEPAGE="https://github.com/FireBurn/webrtc https://github.com/webrtc-sdk/webrtc"
SRC_URI="https://github.com/FireBurn/webrtc/releases/download/gentoo/${PV}/${P}.tar.xz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip"

DEPEND="
	dev-libs/glib:2
	media-libs/mesa
	media-video/pipewire
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/libdrm
"
BDEPEND="
	app-arch/cpio
	${PYTHON_DEPS}
	dev-build/gn
	dev-build/ninja
	llvm-core/clang
	llvm-core/lld
	llvm-core/llvm
"

DESTDIR=/usr/lib/libwebrtc

pkg_setup() {
	python-any-r1_pkg_setup
}

src_compile() {
	# gn takes its flags from args.gn, not from the environment, and the
	# library is meant to carry the flags it was built with
	tc-export CC CXX
	edo ./gentoo/build.sh "${S}" "${WORKDIR}/libwebrtc"
}

src_install() {
	insinto "${DESTDIR}"
	doins -r "${WORKDIR}/libwebrtc/."
}
