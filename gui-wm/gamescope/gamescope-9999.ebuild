# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit fcaps git-r3 meson

EGIT_REPO_URI="https://github.com/ValveSoftware/gamescope.git"
DESCRIPTION="Efficient micro-compositor for running games"
HOMEPAGE="https://github.com/ValveSoftware/gamescope"
KEYWORDS="-*"
LICENSE="BSD-2"
SLOT="0"
IUSE="pipewire +wsi-layer"

RDEPEND="
	>=dev-libs/wayland-1.21
	>=dev-libs/wayland-protocols-1.17
	gui-libs/libdecor
	>=media-libs/libavif-1.0.0:=
	>=media-libs/libdisplay-info-0.1.1
	media-libs/libsdl2[video,vulkan]
	media-libs/vulkan-loader
	sys-apps/hwdata
	sys-libs/libcap
	sys-auth/seatd
	>=x11-libs/libdrm-2.4.109
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libxkbcommon
	x11-libs/libXmu
	x11-libs/libXrender
	x11-libs/libXres
	x11-libs/libXtst
	x11-libs/libXxf86vm
	pipewire? ( >=media-video/pipewire-0.3:= )
	wsi-layer? ( x11-libs/libxcb )
"
DEPEND="
	${RDEPEND}
	>=dev-libs/stb-20240201-r1
	dev-util/vulkan-headers
	media-libs/glm
	dev-util/spirv-headers
	wsi-layer? ( >=media-libs/vkroots-0_p20231108 )
"
BDEPEND="
	dev-util/glslang
	dev-util/wayland-scanner
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-deprecated-stb.patch
)

FILECAPS=(
	cap_sys_nice usr/bin/${PN}
)

src_prepare() {
	default
}

src_configure() {
	local emesonargs=(
		--force-fallback-for=vkroots
		-Dbenchmark=disabled
		-Denable_openvr_support=false
		$(meson_feature pipewire)
		$(meson_use wsi-layer enable_gamescope_wsi_layer)
	)
	meson_src_configure
}
