# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=${PV}
ROCM_SUPPORTED_TARGETS=(
	gfx908 gfx90a gfx942 gfx950
	gfx1100 gfx1101 gfx1102 gfx1103 gfx1150 gfx1151 gfx1152 gfx1153
	gfx1200 gfx1201 gfx1250
)
PYTHON_COMPAT=( python3_{11..14} )

LLVM_COMPAT=( 23 )

inherit cmake flag-o-matic llvm-r2 multiprocessing python-any-r1 rocm

DESCRIPTION="General matrix-matrix operations library for AMD Instinct accelerators"
HOMEPAGE="https://github.com/ROCm/rocm-libraries/tree/develop/projects/hipblaslt"
SRC_URI="
	https://github.com/ROCm/rocm-libraries/releases/download/therock-10.0/hipblaslt.tar.gz -> hipblaslt-${PV}.tar.gz
	https://github.com/ROCm/rocm-libraries/releases/download/therock-10.0/origami.tar.gz -> origami-${PV}.tar.gz
	https://github.com/ROCm/rocm-libraries/releases/download/therock-10.0/stinkytofu.tar.gz -> stinkytofu-${PV}.tar.gz
"

S="${WORKDIR}/hipblaslt"
ORIGAMI_S="${WORKDIR}/origami"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64"

IUSE="benchmark roctracer test"
REQUIRED_USE="test? ( benchmark )"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-util/hip:${SLOT}
	sci-libs/hipBLAS-common:${SLOT}
	roctracer? ( dev-util/roctracer:${SLOT} )
	benchmark? (
		sci-libs/flexiblas
	)
"
DEPEND="
	${RDEPEND}
	dev-cpp/msgpack-cxx
	llvm-runtimes/openmp
"
BDEPEND="
	${PYTHON_DEPS}
	dev-build/rocm-cmake
	dev-util/hipcc:${SLOT}
	$(python_gen_any_dep "
		dev-python/msgpack[\${PYTHON_USEDEP}]
		dev-python/pyyaml[\${PYTHON_USEDEP}]
		dev-python/joblib[\${PYTHON_USEDEP}]
		dev-python/nanobind[\${PYTHON_USEDEP}]
		dev-python/setuptools[\${PYTHON_USEDEP}]
	")
	$(llvm_gen_dep "llvm-core/clang:\${LLVM_SLOT}")
	test? (
		dev-cpp/gtest
		sci-libs/flexiblas
	)
"

PATCHES=(
	"${FILESDIR}/${PN}-10.0.0-codegen.patch"
)

python_check_deps() {
	python_has_version "dev-python/msgpack[${PYTHON_USEDEP}]" &&
	python_has_version "dev-python/pyyaml[${PYTHON_USEDEP}]" &&
	python_has_version "dev-python/joblib[${PYTHON_USEDEP}]" &&
	python_has_version "dev-python/nanobind[${PYTHON_USEDEP}]" &&
	python_has_version "dev-python/setuptools[${PYTHON_USEDEP}]"
}

pkg_setup() {
	QA_FLAGS_IGNORED="usr/$(get_libdir)/hipblaslt/library/.*"
	python-any-r1_pkg_setup
}

src_prepare() {
	local shebangs=()
	mapfile -t shebangs < <(grep -rl "#!/usr/bin/env python3" tensilelite/Tensile || true)
	if (( ${#shebangs[@]} )); then
		python_fix_shebang -q "${shebangs[@]}"
	fi

	rocm_use_hipcc

	sed -e "s:\$(ROCM_PATH)/bin/amdclang++:$(get_llvm_prefix)/bin/clang++:g" \
		-i tensilelite/Makefile || die

	# Fix compiler validation (just a validation)
	sed -e 's/amdclang++/hipcc/g' -e 's/amdclang/hipcc/g' \
		-i tensilelite/Tensile/Toolchain/Validators.py \
		-i tensilelite/Tensile/Tests/unit/test_MatrixInstructionConversion.py || die

	# hipcc adds -lamdhip64 when linking, which breaks device code objects
	sed -e 's:${CMAKE_CXX_COMPILER};-target;amdgcn:${TENSILELITE_ASSEMBLER};-target;amdgcn:' \
		-i device-library/extops/CMakeLists.txt || die

	# Do not install tests
	sed -e "s/COMPONENT tests/COMPONENT tests EXCLUDE_FROM_ALL/" -i CMakeLists.txt || die

	sed -e 's:../../shared/origami:../origami:' -i CMakeLists.txt || die
	sed -e '/        include(FetchContent)/,/        FetchContent_MakeAvailable(nanobind)/c\        find_package(nanobind REQUIRED CONFIG)' \
		-i tensilelite/rocisa/CMakeLists.txt || die
	sed -e 's:../../../../shared/stinkytofu:../../../stinkytofu:' \
		-i tensilelite/rocisa/CMakeLists.txt || die
	sed -e '/include(ClangTidy)/d' -e '/add_clang_tidy_custom_target()/d' \
		-i "${WORKDIR}/stinkytofu/CMakeLists.txt" || die

	cmake_src_prepare

	pushd "${ORIGAMI_S}" || die
		local PATCHES=()
		cmake_src_prepare
	popd || die
}

src_configure() {
	rocm_use_hipcc

	# too many warnings
	append-cxxflags -Wno-explicit-specialization-storage-class

	append-ldflags "-fuse-ld=lld"

	local targets="$(get_amdgpu_flags)"
	local Tensile_SKIP_BUILD=$([ "${AMDGPU_TARGETS[*]}" = "" ] && echo ON || echo OFF )
	local HIPBLASLT_ENABLE_DEVICE=$([ "${AMDGPU_TARGETS[*]}" != "" ] && echo ON || echo OFF )
	local HIPBLASLT_ENABLE_EXTOPS=ON
	[[ " ${AMDGPU_TARGETS[*]} " == *" gfx12"* ]] && HIPBLASLT_ENABLE_EXTOPS=OFF

	# targets has a trailing semicolon, this trips up Tensile's input parser, so carefully prune
	local mycmakeargs=(
		-DGPU_TARGETS="${targets::-1}"
		-DHIPBLASLT_ENABLE_CLIENT="$(usex benchmark ON $(usex test ON OFF))"
		-DHIPBLASLT_ENABLE_SAMPLES=OFF
		-DHIPBLASLT_ENABLE_DEVICE=${HIPBLASLT_ENABLE_DEVICE}
		-DHIPBLASLT_ENABLE_EXTOPS=${HIPBLASLT_ENABLE_EXTOPS}
		-DHIPBLASLT_ENABLE_MARKER="$(usex roctracer ON OFF)"
		-DHIPBLASLT_ENABLE_ROCROLLER=OFF
		-DHIPBLASLT_ENABLE_FETCH=OFF
		-DHIPBLASLT_BUNDLE_PYTHON_DEPS=ON
		-Dnanobind_DIR="$(python_get_sitedir)/nanobind/cmake"
		-DPython_EXECUTABLE="${PYTHON}"
		-DROCM_SYMLINK_LIBS=OFF
		-DTENSILELITE_BUILD_PARALLEL_LEVEL=$(makeopts_jobs)
		-DTENSILELITE_ASSEMBLER="$(get_llvm_prefix)/bin/clang++"
		-DHIPBLASLT_BUILD_TESTING="$(usex test ON OFF)"
		-Wno-dev
	)

	if use test || use benchmark; then
		# HIPBLASLT_ENABLE_CLIENT=ON branch
		mycmakeargs+=(
			-DBLA_PKGCONFIG_BLAS=ON
			-DBLA_VENDOR=FlexiBLAS
			-DHIPBLASLT_ENABLE_BLIS=OFF
		)
	fi

	cmake_src_configure
}

src_compile() {
	local -x ROCM_PATH="${EPREFIX}/usr"
	# set PYTHONPATH to load Tensile from virtualenv, not the system-wide one
	local -x PYTHONPATH="${S}_build/virtualenv/lib/${EPYTHON}/site-packages"
	local -x TENSILE_ROCM_ASSEMBLER_PATH="$(get_llvm_prefix)/bin/clang++"
	# TensileCreateLibrary reads CMAKE_CXX_COMPILER again
	local -x CMAKE_CXX_COMPILER="$(get_llvm_prefix)/bin/clang++"
	cmake_src_compile
}

src_install() {
	cmake_src_install

	# Stop llvm-strip from removing .strtab section from *.hsaco files,
	# otherwise rocclr/elf/elf.cpp complains with "failed: null sections(STRTAB)" and crashes
	dostrip -x /usr/$(get_libdir)/hipblaslt/library/
}

src_test() {
	check_amdgpu
	cmake_build tensilelite-device-libraries-validate

	# Expected time for 7900 XTX: 340s (full) or 5s with GTEST_FILTER='*quick*'
	# Fails in `MatrixTransformTest.MultipleDevices` in dGPU+iGPU combination
	HIP_VISIBLE_DEVICES=0 cmake_src_test
}
