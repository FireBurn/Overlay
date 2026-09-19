# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/ROCm/rocm-cmake.git"
	inherit git-r3
else
	SRC_URI="https://github.com/ROCm/rocm-cmake/archive/refs/tags/therock-10.0.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
	S="${WORKDIR}/rocm-cmake-therock-10.0"
fi

DESCRIPTION="Radeon Open Compute CMake Modules"
HOMEPAGE="https://github.com/ROCm/rocm-cmake"
LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
RESTRICT="test"

DOCS=( CHANGELOG.md LICENSE README.md )

src_prepare() {
	sed -e "/CMAKE_INSTALL_LIBDIR/s:lib:$(get_libdir):" \
		-i "share/rocmcmakebuildtools/cmake/ROCMCreatePackage.cmake" \
		-i "share/rocmcmakebuildtools/cmake/ROCMInstallTargets.cmake" || die
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-Wno-dev
	)
	cmake_src_configure
}
