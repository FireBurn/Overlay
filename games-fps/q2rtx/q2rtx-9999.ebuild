# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

EGIT_REPO_URI="https://github.com/NVIDIA/Q2RTX.git"
EGIT_SUBMODULES=( '-*' 'extern/stb' 'extern/tinyobjloader-c' )
inherit git-r3

RELEASE_VER="1.8.0"
SRC_URI="
	https://github.com/NVIDIA/Q2RTX/releases/download/v${RELEASE_VER}/q2rtx-${RELEASE_VER}-linux.tar.gz
"

DESCRIPTION="NVIDIA's implementation of RTX ray-tracing in Quake II"
HOMEPAGE="https://github.com/NVIDIA/Q2RTX"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	media-libs/libsdl2
	media-libs/sdl2-image
	media-libs/sdl2-mixer
	media-libs/openal
	sys-libs/zlib
	net-misc/curl
	dev-util/vulkan-headers
	dev-util/glslang
"

RDEPEND="
	media-libs/libsdl2
	media-libs/sdl2-image
	media-libs/sdl2-mixer
	media-libs/openal
	sys-libs/zlib
	net-misc/curl
"

PATCHES="${FILESDIR}/install-to-bin.patch"

src_unpack() {
	git-r3_src_unpack

	unpack q2rtx-${RELEASE_VER}-linux.tar.gz
}

src_prepare() {
	cmake_src_prepare
	einfo ${P}
	einfo ${S}

	mv ${WORKDIR}/${PN}/baseq2/blue_noise.pkz ${S}/baseq2/blue_noise.pkz || die
	mv ${WORKDIR}/${PN}/baseq2/q2rtx_media.pkz ${S}/baseq2/q2rtx_media.pkz || die
	mkdir -p ${S}/baseq2/shareware || die
	mv ${WORKDIR}/${PN}/baseq2/pak0.pak ${S}/baseq2/shareware/pak0.pak || die
	mv ${WORKDIR}/${PN}/baseq2/players ${S}/baseq2/shareware/players || die
}

src_configure() {
	local mycmakeargs=(
		-DCONFIG_LINUX_PACKAGING_SUPPORT=ON
		-DCONFIG_BUILD_GLSLANG=OFF
		-DUSE_SYSTEM_ZLIB=ON
		-DUSE_SYSTEM_OPENAL=ON
		-DUSE_SYSTEM_CURL=ON
		-DUSE_SYSTEM_SDL2=ON
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
}

pkg_postinst() {
	ewarn "This package does not include the required Quake II data files."
	ewarn "You must copy the .pak files (pak0.pak, etc.) from your"
	ewarn "original Quake II game installation into:"
	ewarn "  \${HOME}/.local/share/quake2rtx/baseq2"
}
