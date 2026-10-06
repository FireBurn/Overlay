# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="Open-source reader for AMD SQTT thread traces (.rgp and AMD_RDF captures)"
HOMEPAGE="https://github.com/FireBurn/OpenRGP"
EGIT_REPO_URI="https://github.com/FireBurn/OpenRGP.git"

LICENSE="MIT"
SLOT="0"
IUSE="gui"

DEPEND="
	app-arch/zstd:=
	gui? ( dev-qt/qtbase:6[gui,widgets] )
"
# llvm-objdump (AMDGPU target) identifies the shader each wave ran
RDEPEND="
	${DEPEND}
	llvm-core/llvm[llvm_targets_AMDGPU]
"
BDEPEND="virtual/pkgconfig"

src_configure() {
	local mycmakeargs=(
		-DOPENRGP_GUI=$(usex gui)
	)
	cmake_src_configure
}
