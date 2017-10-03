# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit git-r3 eutils cmake-utils

DESCRIPTION="Examples and demos for the Vulkan API"
HOMEPAGE="https://github.com/SaschaWillems/Vulkan"

EGIT_REPO_URI="https://github.com/SaschaWillems/Vulkan.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

RDEPEND="media-libs/vulkan-loader
	dev-util/cmake
	media-libs/assimp"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	cmake-utils_src_prepare
}

src_configure() {
    local mycmakeargs=(
		-DRESOURCE_INSTALL_DIR=/usr/share/vulkan/data/
		-CMAKE_INSTALL_BINDIR=/usr/share/vulkan/demos/
    )
	cmake-utils_src_configure
}

src_install() {
	mkdir -p "${D}"/usr/share/vulkan/{demos,data}

	exeinto /usr/share/vulkan/demos
	doexe ${BUILD_DIR}/bin/vulkanscene
	rm ${BUILD_DIR}/bin/vulkanscene

	cd ${BUILD_DIR}/bin/
	for filename in * ; do mv "$filename" "vulkan$filename"; done;
	doexe ${BUILD_DIR}/bin/*
 

	insinto /usr/share/vulkan/data
	doins -r ${S}/data/*
}
