# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}

inherit cmake rocm

DESCRIPTION="Generate pseudo-random and quasi-random numbers"
HOMEPAGE="https://github.com/ROCm/rocm-libraries/tree/develop/projects/rocrand"
SRC_URI="https://github.com/ROCm/rocm-libraries/releases/download/therock-10.0/rocrand.tar.gz -> rocrand-${PV}.tar.gz"
S="${WORKDIR}/rocrand"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE="benchmark test"
REQUIRED_USE="${ROCM_REQUIRED_USE}"

RESTRICT="!test? ( test )"

RDEPEND="
	dev-util/hip:${SLOT}
	benchmark? ( dev-cpp/benchmark )
"
DEPEND="${RDEPEND}
	dev-build/rocm-cmake
	test? ( dev-cpp/gtest )"

src_prepare() {
	# development-only precomputed generator tools
	sed -i 's/^[[:space:]]*add_subdirectory(tools)$/# &/' CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	# clang++ --hip-link cannot locate libamdhip64.so in the multilib layout
	rocm_use_hipcc

	export ROCM_PATH="${EPREFIX}/usr"

	local mycmakeargs=(
		-DCMAKE_SKIP_RPATH=ON
		-DAMDGPU_TARGETS="$(get_amdgpu_flags)"
		-DROCM_SYMLINK_LIBS=OFF
		-DBUILD_TEST=$(usex test ON OFF)
		-DBUILD_BENCHMARK=$(usex benchmark ON OFF)
	)

	cmake_src_configure
}

src_test() {
	check_amdgpu
	export LD_LIBRARY_PATH="${BUILD_DIR}/library"
	# uses HMM to fit tests to default <512M iGPU VRAM
	ROCRAND_USE_HMM="1" cmake_src_test -j1
}
