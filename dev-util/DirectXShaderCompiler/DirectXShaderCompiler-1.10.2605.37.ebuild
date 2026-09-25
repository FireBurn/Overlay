# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit cmake check-reqs python-any-r1

DESCRIPTION="Microsoft DirectX Shader Compiler which is based on LLVM/Clang"
HOMEPAGE="https://github.com/microsoft/DirectXShaderCompiler"

# Submodule SHAs pinned by the release tag:
#   git ls-tree v${PV} external/
# Using the exact commits DXC was developed and tested against avoids any
# header compatibility issues between the bundled components.
#
# TODO: patch external/CMakeLists.txt to use find_package() so these can be
# properly unbundled against dev-util/spirv-headers, dev-util/spirv-tools and
# dev-util/directx-headers.
SPIRV_HEADERS_COMMIT="29981f65241605e08b0ede4cfeb999fe3b723c6a"
SPIRV_TOOLS_COMMIT="1c336172641682bab6e066767d09fdff1d826467"
DIRECTX_HEADERS_COMMIT="980971e835876dc0cde415e8f9bc646e64667bf7"

SRC_URI="
	https://github.com/microsoft/DirectXShaderCompiler/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/KhronosGroup/SPIRV-Headers/archive/${SPIRV_HEADERS_COMMIT}.tar.gz
		-> DirectXShaderCompiler-headers-${SPIRV_HEADERS_COMMIT}.tar.gz
	https://github.com/KhronosGroup/SPIRV-Tools/archive/${SPIRV_TOOLS_COMMIT}.tar.gz
		-> DirectXShaderCompiler-tools-${SPIRV_TOOLS_COMMIT}.tar.gz
	https://github.com/microsoft/DirectX-Headers/archive/${DIRECTX_HEADERS_COMMIT}.tar.gz
		-> DirectXShaderCompiler-directxheaders-${DIRECTX_HEADERS_COMMIT}.tar.gz
"

LICENSE="Apache-2.0-with-LLVM-exceptions UoI-NCSA BSD public-domain rc"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="${PYTHON_DEPS}"
RDEPEND="
	virtual/zlib:=
	>=dev-libs/libffi-3.4.2-r1:0=
"
BDEPEND="sys-devel/gnuconfig"

CHECKREQS_MEMORY="4G"
CHECKREQS_DISK_BUILD="4G"

src_prepare() {
	# Replace the empty stub directories with the downloaded source tarballs,
	# using the exact submodule commits the release was pinned to.
	rm -d "${S}"/external/SPIRV* || die
	rm -d "${S}"/external/DirectX* || die
	mv "${WORKDIR}/SPIRV-Headers-${SPIRV_HEADERS_COMMIT}" \
		"${S}/external/SPIRV-Headers" || die
	mv "${WORKDIR}/SPIRV-Tools-${SPIRV_TOOLS_COMMIT}" \
		"${S}/external/SPIRV-Tools" || die
	mv "${WORKDIR}/DirectX-Headers-${DIRECTX_HEADERS_COMMIT}" \
		"${S}/external/DirectX-Headers" || die

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-Wno-dev
		# Use the generated sources upstream ships: regenerating them runs
		# clang-format, whose output differs between LLVM versions, and the
		# build fails if the result does not match byte for byte
		-DHLSL_DISABLE_SOURCE_GENERATION=ON
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/llvm/dxc"
		-DLLVM_BUILD_DOCS=0
		-DLLVM_BUILD_TOOLS=0
		# Disable test infrastructure: DXC's clang/test cmake uses
		# ExternalProject_Add to download old DXC release zips at build time,
		# which fails in a network-restricted Portage sandbox.
		-DLLVM_INCLUDE_TESTS=OFF
		-DCLANG_INCLUDE_TESTS=OFF
		-DSPIRV_BUILD_TESTS=0
		-DLLVM_ENABLE_WERROR=0
		-DSPIRV_WERROR=0
		-DSPIRV_WARN_EVERYTHING=0
		-DBUILD_SHARED_LIBS=OFF
		-DLLVM_VERSION_SUFFIX=dxc
		-C "${S}/cmake/caches/PredefinedParams.cmake"
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	cat > "99${PN}" <<-EOF
		LDPATH="${EPREFIX}/usr/lib/llvm/dxc/lib"
	EOF
	doenvd "99${PN}"
	dosym -r /usr/lib/llvm/dxc/bin/dxc /usr/bin/dxc
}
