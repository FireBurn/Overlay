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

RDEPEND="|| ( media-libs/vulkan-loader media-libs/vulkan-base )
	dev-util/cmake
	media-libs/assimp"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	cmake-utils_src_prepare

	epatch "${FILESDIR}"/data.patch
}

src_configure() {
	cmake-utils_src_configure
}

src_install() {
	mkdir -p "${D}"/usr/share/vulkan/{demos,data}

	exeinto /usr/share/vulkan/demos
	doexe "${S}"/bin/vulkanscene
	rm "${S}"/bin/{vulkanscene,assimp-vc140-mt.dll}

	cd "${S}"/bin/
	for filename in * ; do mv "$filename" "vulkan$filename"; done;
	doexe "${S}"/bin/*

	insinto /usr/share/vulkan/data
	doins -r "${S}"/data/*

	# create an entry for the newly created vulkan libs
        cat << EOF > "${D}"/etc/env.d/89vulkan
PATH="/usr/share/vulkan/demos"
EOF
}
