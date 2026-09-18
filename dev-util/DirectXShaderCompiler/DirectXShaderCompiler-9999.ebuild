# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit cmake check-reqs python-any-r1

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
fi

DESCRIPTION="Microsoft DirectX Shader Compiler which is based on LLVM/Clang"
HOMEPAGE="https://github.com/microsoft/DirectXShaderCompiler"

# Submodule SHAs pinned by DXC v1.9.2602 (commit 21d28f72):
SPIRV_HEADERS_COMMIT="04f10f650d514df88b76d25e83db360142c7b174"
SPIRV_TOOLS_COMMIT="fbe4f3ad913c44fe8700545f8ffe35d1382b7093"
DIRECTX_HEADERS_COMMIT="980971e835876dc0cde415e8f9bc646e64667bf7"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/FireBurn/DirectXShaderCompiler.git"
	EGIT_SUBMODULES=( '*' )
else
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
fi

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
	if [[ ${PV} != 9999 ]]; then
		# Replace the empty stub directories with the downloaded source tarballs
		rm -d "${S}"/external/SPIRV* || die
		rm -d "${S}"/external/DirectX* || die
		mv "${WORKDIR}/SPIRV-Headers-${SPIRV_HEADERS_COMMIT}" \
			"${S}/external/SPIRV-Headers" || die
		mv "${WORKDIR}/SPIRV-Tools-${SPIRV_TOOLS_COMMIT}" \
			"${S}/external/SPIRV-Tools" || die
		mv "${WORKDIR}/DirectX-Headers-${DIRECTX_HEADERS_COMMIT}" \
			"${S}/external/DirectX-Headers" || die
	fi

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
