# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit cmake python-any-r1

MY_P=OpenXR-SDK-release-${PV}

DESCRIPTION="Khronos OpenXR loader and API layers"
HOMEPAGE="https://www.khronos.org/openxr/"
SRC_URI="https://github.com/KhronosGroup/OpenXR-SDK/archive/refs/tags/release-${PV}.tar.gz -> ${MY_P}.tar.gz"
S=${WORKDIR}/${MY_P}

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-libs/jsoncpp:=
	media-libs/vulkan-loader
	media-libs/libglvnd
	x11-libs/libX11
"
RDEPEND="${DEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	virtual/pkgconfig
"

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTS=OFF
		-DBUILD_CONFORMANCE_TESTS=OFF
		-DBUILD_WITH_SYSTEM_JSONCPP=ON
		-DHAVE_FILESYSTEM_WITHOUT_LIB=0
	)
	cmake_src_configure
}
