# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit check-reqs cmake git-r3 python-any-r1

DESCRIPTION="Microsoft DirectX Shader Compiler which is based on LLVM/Clang"
HOMEPAGE="https://github.com/microsoft/DirectXShaderCompiler"

# Fork of upstream carrying a Vulkan compatibility patch not yet merged:
# https://github.com/FireBurn/DirectXShaderCompiler
EGIT_REPO_URI="https://github.com/FireBurn/DirectXShaderCompiler.git"
EGIT_SUBMODULES=( '*' )

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
