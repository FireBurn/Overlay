# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

LLVM_COMPAT=( 21 )
PYTHON_COMPAT=( python3_{11..14} )
inherit cmake llvm.org llvm-r1 python-any-r1

DESCRIPTION="OpenCL C library"
HOMEPAGE="https://libclc.llvm.org/"

LICENSE="Apache-2.0-with-LLVM-exceptions || ( MIT BSD )"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~loong ~riscv ~x86"
IUSE="+spirv video_cards_nvidia video_cards_r600 video_cards_radeonsi"

BDEPEND="
	${PYTHON_DEPS}
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}
	')
	spirv? ( llvm-core/llvm[llvm_targets_SPIRV(+)] )
"

LLVM_COMPONENTS=( libclc )
llvm.org_set_globals

PATCHES=(
		"${FILESDIR}/spirv-target.patch"
	)

pkg_setup() {
	llvm-r1_pkg_setup
	python-any-r1_pkg_setup
}

src_configure() {
	local libclc_targets=(
		"clspv--"
		"clspv64--"
	)

	use spirv && libclc_targets+=(
		"spirv-mesa3d-"
		"spirv64-mesa3d-"
	)
	use video_cards_nvidia && libclc_targets+=(
		"nvptx--"
		"nvptx64--"
		"nvptx--nvidiacl"
		"nvptx64--nvidiacl"
	)
	use video_cards_r600 && libclc_targets+=(
		"r600--"
	)
	use video_cards_radeonsi && libclc_targets+=(
		"amdgcn--"
		"amdgcn-mesa-mesa3d"
		"amdgcn--amdhsa"
	)

	libclc_targets=${libclc_targets[*]}
	local mycmakeargs=(
		-DLIBCLC_TARGETS_TO_BUILD="${libclc_targets// /;}"
		-DLIBCLC_USE_SPIRV_BACKEND=true
	)
	cmake_src_configure
}
