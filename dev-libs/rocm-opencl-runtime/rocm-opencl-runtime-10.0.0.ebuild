# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_SKIP_GLOBALS=1
LLVM_COMPAT=( 23 )

inherit cmake flag-o-matic llvm-r2 rocm

DESCRIPTION="Radeon Open Compute OpenCL runtime"
HOMEPAGE="https://github.com/ROCm/rocm-systems/tree/develop/projects/clr"
SRC_URI="https://github.com/ROCm/rocm-systems/releases/download/therock-10.0/clr.tar.gz -> rocm-clr-${PV}.tar.gz"
S="${WORKDIR}/clr"

LICENSE="Apache-2.0 MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"
IUSE="debug test"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-libs/rocr-runtime:${SLOT}
	dev-libs/rocm-comgr:${SLOT}
	dev-libs/rocm-device-libs:${SLOT}
	>=virtual/opencl-3
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-build/rocm-cmake
	media-libs/glew
	test? ( x11-apps/mesa-progs[X] )
"

PATCHES=(
	"${FILESDIR}"/${PN}-10.0.0-fix-lib-version.patch
	"${FILESDIR}"/${PN}-10.0.0-vega-apu-xnack.patch
)

src_prepare() {
	sed -e '/cmake_minimum_required/ s/3\.[35]/3.10/' \
		-i opencl/khronos/icd/CMakeLists.txt \
			opencl/khronos/headers/opencl2.2/tests/CMakeLists.txt || die
	cmake_src_prepare
}

src_configure() {
	llvm_prepend_path "${LLVM_SLOT}"
	filter-flags '-march=*' '-mtune=*'
	append-flags -fno-strict-aliasing
	filter-lto
	append-ldflags $(test-flags-CCLD -Wl,--undefined-version)
	append-cflags -fcommon

	local mycmakeargs=(
		-Wno-dev
		-DROCM_PATH="${EPREFIX}/usr"
		-DBUILD_TESTS=$(usex test ON OFF)
		-DEMU_ENV=ON
		-DBUILD_ICD=OFF
		-DCLR_BUILD_HIP=OFF
		-DCLR_BUILD_OCL=ON
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=ON
	)
	cmake_src_configure
}

src_install() {
	insinto /etc/OpenCL/vendors
	doins opencl/config/amdocl64.icd

	cd "${BUILD_DIR}/opencl" || die
	insinto /usr/$(get_libdir)
	doins amdocl/libamdocl64.so*
	doins tools/cltrace/libcltrace.so
}

src_test() {
	check_amdgpu
	cd "${BUILD_DIR}/tests/ocltst" || die
	export OCL_ICD_FILENAMES="${BUILD_DIR}/amdocl/libamdocl64.so"
	./ocltst -m "$(realpath liboclruntime.so)" -A oclruntime.exclude || die
	./ocltst -m "$(realpath liboclperf.so)" -A oclperf.exclude || die
}
