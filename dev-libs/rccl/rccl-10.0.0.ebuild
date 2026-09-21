# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
ROCM_VERSION=${PV}

inherit cmake python-any-r1 rocm

DESCRIPTION="Collective communication library for AMD GPUs (NCCL-compatible)"
HOMEPAGE="https://github.com/ROCm/rocm-systems/tree/develop/projects/rccl"
SRC_URI="https://github.com/ROCm/rocm-systems/releases/download/therock-10.0/${PN}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}"

LICENSE="BSD"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE="test"
RESTRICT="!test? ( test )"
REQUIRED_USE="${ROCM_REQUIRED_USE}"

RDEPEND="
	dev-libs/rocr-runtime:${SLOT}
	dev-libs/libfmt
	dev-util/hip:${SLOT}
	dev-util/roctracer:${SLOT}
"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	dev-build/rocm-cmake
	dev-util/hipify-clang
	test? ( dev-cpp/gtest )
"

src_prepare() {
	# do not force /usr/lib, break multilib
	sed -i '/set(CMAKE_INSTALL_LIBDIR lib CACHE STRING/d' cmake/Dependencies.cmake || die

	cmake_src_prepare
}

src_configure() {
	python_setup
	rocm_use_hipcc

	local targets="$(get_amdgpu_flags)"
	local mycmakeargs=(
		-DROCM_PATH="${EPREFIX}/usr"
		-DEXPLICIT_ROCM_VERSION=${PV}
		-DGPU_TARGETS="${targets::-1}"
		# requires dev-util/rocprofiler-register
		-DRCCL_ROCPROFILER_REGISTER=OFF
		-DBUILD_TESTS=$(usex test)
		-Wno-dev
	)

	cmake_src_configure
}
