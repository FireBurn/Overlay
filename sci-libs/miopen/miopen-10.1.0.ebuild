# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}
LLVM_COMPAT=( 23 24 )

inherit cmake flag-o-matic llvm-r2 rocm

DESCRIPTION="AMD's Machine Intelligence Library"
HOMEPAGE="https://github.com/ROCm/rocm-libraries/tree/develop/projects/miopen"
SRC_URI="https://github.com/ROCm/rocm-libraries/releases/download/therock-10.1/${PN}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE="debug roctracer test"
REQUIRED_USE="${ROCM_REQUIRED_USE}"

# tests can freeze machine depending on gpu/kernel
RESTRICT="test"

RDEPEND="
	dev-util/hip:${SLOT}
	dev-db/sqlite:3
	app-arch/bzip2
	sci-libs/rocRAND:${SLOT}
	dev-libs/boost:=
	dev-libs/rocm-comgr:${SLOT}
	sci-libs/rocBLAS:${SLOT}
	sci-libs/hipBLASLt:${SLOT}
	roctracer? ( dev-util/roctracer:${SLOT} )
"
DEPEND="
	${RDEPEND}
	dev-cpp/nlohmann_json
	>=dev-libs/half-1.12.0-r1
	test? ( dev-cpp/gtest )

	amdgpu_targets_gfx908? ( =dev-cpp/frugally-deep-0.15* )
	amdgpu_targets_gfx942? ( =dev-cpp/frugally-deep-0.15* )
"
BDEPEND="
	dev-build/rocm-cmake
	$(llvm_gen_dep "llvm-core/clang:\${LLVM_SLOT}")
"

src_prepare() {
	cmake_src_prepare
	# hipconv builds every arch dir regardless of GPU_TARGETS; for unserved
	# archs it fell back to the first build GPU, which cannot compile the
	# arch-specific builtins (target-feature check). The _1k bf16 MFMA
	# builtins take i16 vectors, so cast the __bf16x4 operands explicitly.
	patch -p1 < "${FILESDIR}/miopen-10.1.0-hipconv-vanilla-llvm.patch" || die

	if (( LLVM_SLOT < 24 )); then
		# llvm-23's AMDGPU backend aborts on the gfx950 kernels ("illegal VGPR
		# to SGPR copy"); leave out the arch libraries that were not asked for
		local arch
		for arch in cdna4:gfx950 cdna5:gfx1250; do
			use amdgpu_targets_${arch#*:} || rm -r src/hipconv/src/arch/${arch%:*} || die
		done
	fi
}

src_configure() {
	rocm_use_clang
	# clang++ --hip-link cannot locate libamdhip64.so in the multilib layout
	append-ldflags -no-hip-rt -L"${EPREFIX}/usr/$(get_libdir)" -lamdhip64

	if ! use debug; then
		append-cflags "-DNDEBUG"
		append-cxxflags "-DNDEBUG"
		CMAKE_BUILD_TYPE="Release"
	else
		CMAKE_BUILD_TYPE="Debug"
	fi

	local use_ai_tuning=OFF
	if use amdgpu_targets_gfx908 \
	|| use amdgpu_targets_gfx942; then
		use_ai_tuning=ON
	fi

	# Too many warnings
	append-cxxflags -Wno-thread-safety-analysis
	# hipconv's cdna4 swizzle self-checks exceed the default constexpr step
	# limit (1048576) under vanilla clang.
	append-cxxflags -fconstexpr-steps=33554432

	local mycmakeargs=(
		-DCMAKE_SKIP_RPATH=ON
		# CMake cannot identify the HIP compiler here (its id test links
		# libamdhip64.so from /usr/lib, but the multilib layout keeps it in
		# /usr/lib64), so no C++ standard is passed for HIP sources; hipconv
		# requires C++20.
		-DCMAKE_HIP_FLAGS="-std=c++20 -fconstexpr-steps=33554432"
		# ... and without the compiler id CMake also omits -x hip, so the
		# .cpp kernels would be compiled as plain C++
		-DCMAKE_HIP_COMPILE_OBJECT="<CMAKE_HIP_COMPILER> -x hip <DEFINES> <INCLUDES> <FLAGS> -o <OBJECT> -c <SOURCE>"
		-DGPU_TARGETS="$(get_amdgpu_flags)"
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		-DMIOPEN_BACKEND=HIP
		-DBoost_USE_STATIC_LIBS=OFF
		-DMIOPEN_USE_MLIR=OFF
		-DMIOPEN_USE_ROCTRACER=$(usex roctracer ON OFF)
		-DMIOPEN_USE_ROCBLAS=ON
		-DMIOPEN_USE_HIPBLASLT=ON
		-DMIOPEN_USE_COMPOSABLEKERNEL=OFF
		-DMIOPEN_STRIP_SYMBOLS=OFF
		-DBUILD_TESTING=$(usex test ON OFF)
		-DROCM_SYMLINK_LIBS=OFF
		-DROCM_ENABLE_CLANG_TIDY=OFF
		-DMIOPEN_AMDGCN_ASSEMBLER="$(get_llvm_prefix)/bin/clang"
		-DMIOPEN_OFFLOADBUNDLER_BIN="$(get_llvm_prefix)/bin/clang-offload-bundler"
		-DMIOPEN_ENABLE_AI_KERNEL_TUNING=${use_ai_tuning}
		-DMIOPEN_ENABLE_AI_IMMED_MODE_FALLBACK=${use_ai_tuning}
	)

	cmake_src_configure
}

src_test() {
	check_amdgpu
	LD_LIBRARY_PATH="${BUILD_DIR}"/lib MIOPEN_SYSTEM_DB_PATH="${BUILD_DIR}"/share/miopen/db/ cmake_src_test -j1
}
