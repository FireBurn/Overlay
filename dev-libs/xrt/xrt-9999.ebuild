# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="Xilinx Runtime (XRT)"
HOMEPAGE="https://github.com/Xilinx/XRT"
EGIT_REPO_URI="https://github.com/Xilinx/XRT.git"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

IUSE="doc"

# Dependencies identified from build.sh and CMakeLists.txt
# Protobuf is required for the NPU build
COMMON_DEPS="
	dev-debug/systemtap
	dev-libs/boost
	dev-libs/json-c
	dev-libs/libyaml
	dev-python/markdown
	sys-apps/util-linux
	sys-libs/zlib
	virtual/opencl
"
RDEPEND="${COMMON_DEPS}
	dev-libs/protobuf
"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen dev-python/sphinx )
"

src_configure() {
	local mycmakeargs=(
		# Assumes a native build for a standard Gentoo system
		# This is equivalent to '-opt' as it sets the build type to Release.
		-DXRT_NATIVE_BUILD=ON
		-DXRT_NPU=ON
		-DXRT_ENABLE_WERROR=OFF
	)

	cmake_src_configure
}
