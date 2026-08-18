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

IUSE="doc +npu"

VTD_COMMIT="c579b12aba708d81b599bb2c9105ba68f3e721e6"
SRC_URI="
	npu? (
		https://github.com/Xilinx/VTD/raw/${VTD_COMMIT}/archive/strx/xrt_smi_strx.a
		https://github.com/Xilinx/VTD/raw/${VTD_COMMIT}/archive/phx/xrt_smi_phx.a
		https://github.com/Xilinx/VTD/raw/${VTD_COMMIT}/archive/npu3/xrt_smi_npu3.a
	)
"

# Dependencies identified from build.sh and CMakeLists.txt
# Protobuf is required for the NPU build
COMMON_DEPS="
	dev-debug/systemtap
	dev-libs/boost:=
	dev-libs/json-c
	dev-libs/libyaml
	dev-libs/rapidjson
	dev-libs/openssl:=
	dev-python/markdown
	sys-apps/util-linux
	sys-libs/zlib
	virtual/opencl
"
RDEPEND="${COMMON_DEPS}
	dev-libs/protobuf:=
"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen dev-python/sphinx )
"

src_unpack() {
	git-r3_src_unpack

	if use npu; then
		EGIT_REPO_URI="https://github.com/amd/xdna-driver.git" \
		EGIT_CHECKOUT_DIR="${S}/xdna-driver" \
		git-r3_src_unpack
	fi
}

src_prepare() {
	cmake_src_prepare
	# Prevent network access during build/install phase in Gentoo sandbox
	sed -i -e '/COMMAND wget/{N;s|COMMAND wget.*\n.*https://.*|COMMAND touch markdown_graphviz_svg.py|g}' \
		"${S}/src/runtime_src/core/common/aiebu/specification/CMakeLists.txt" || die

	# Remove hardcoded -Werror to allow building with clang and newer GCCs
	find "${S}" -type f \( -name "CMakeLists.txt" -o -name "*.cmake" \) -exec sed -i -e 's/-Werror//g' {} + || die

	if use npu; then
		sed -i -e '/NAMELINK_SKIP/d' "${S}/xdna-driver/src/shim/CMakeLists.txt" || die
		cat >> "${S}/src/CMakeLists.txt" <<-EOF || die
		set(XDNA_COMPONENT "amdxdna")
		set(XDNA_PKG_LIB_DIR "\${CMAKE_INSTALL_LIBDIR}")
		set(XRT_PLUGIN_VERSION_STRING "\${XRT_VERSION_STRING}")
		add_subdirectory(\${CMAKE_SOURCE_DIR}/xdna-driver/src/shim \${CMAKE_BINARY_DIR}/xdna-driver/src/shim)
		EOF
	fi
}

src_configure() {
	local mycmakeargs=(
		# Assumes a native build for a standard Gentoo system
		# This is equivalent to '-opt' as it sets the build type to Release.
		-DXRT_NATIVE_BUILD=ON
		-DXRT_NPU=$(usex npu ON OFF)
		-DXRT_ENABLE_WERROR=OFF
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	if use npu; then
		insinto /usr/share/xrt/amdxdna/bins
		doins "${DISTDIR}/xrt_smi_phx.a"
		doins "${DISTDIR}/xrt_smi_strx.a"
		doins "${DISTDIR}/xrt_smi_npu3.a"
	fi
}
