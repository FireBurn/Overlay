# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION="10.0"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/leejet/stable-diffusion.cpp.git"
	EGIT_SUBMODULES=( 'ggml' )
else
	MY_BUILD="${PV#0_p}"
	MY_COMMIT="4c3cf75"
	MY_PV="master-${MY_BUILD}-${MY_COMMIT}"
	GGML_COMMIT="4bf5f6000653b7881d00963cd6ddb665ccd62a8d"
	SRC_URI="
		https://github.com/leejet/stable-diffusion.cpp/archive/refs/tags/${MY_PV}.tar.gz -> ${P}.tar.gz
		https://github.com/leejet/ggml/archive/${GGML_COMMIT}.tar.gz -> ${PN}-ggml-${GGML_COMMIT:0:10}.tar.gz
	"
	S="${WORKDIR}/stable-diffusion.cpp-${MY_PV}"
fi

inherit cmake cuda linux-info rocm toolchain-funcs

DESCRIPTION="Diffusion model (SD, Flux, Wan, etc.) inference in pure C/C++"
HOMEPAGE="https://github.com/leejet/stable-diffusion.cpp"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

X86_CPU_FLAGS=(
	amx_bf16
	amx_int8
	amx_tile
	avx
	avx2
	avx512_bf16
	avx512_vnni
	avx512f
	avx512vbmi
	avx_vnni
	bmi2
	f16c
	fma3
	sse4_2
)
CPU_FLAGS=( "${X86_CPU_FLAGS[@]/#/cpu_flags_x86_}" )
IUSE="${CPU_FLAGS[*]} blis cuda flexiblas hip openblas opencl +openmp vulkan webm webp"
unset X86_CPU_FLAGS CPU_FLAGS

REQUIRED_USE="
	?? (
		blis
		flexiblas
		openblas
	)
	hip? ( ${ROCM_REQUIRED_USE} )
	webm? ( webp )
"
RESTRICT="test"

CDEPEND="
	blis? ( sci-libs/blis:= )
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
	flexiblas? ( sci-libs/flexiblas:= )
	hip? (
		>=dev-util/hip-10.0:=
		>=sci-libs/hipBLAS-10.0:=
	)
	openblas? ( sci-libs/openblas:= )
	openmp? ( llvm-runtimes/openmp:= )
	webm? ( media-libs/libwebm:= )
	webp? ( media-libs/libwebp:= )
"
DEPEND="${CDEPEND}
	opencl? ( dev-util/opencl-headers )
	vulkan? (
		dev-util/spirv-headers
		dev-util/vulkan-headers
	)
"
RDEPEND="${CDEPEND}
	opencl? ( dev-libs/opencl-icd-loader )
	vulkan? ( media-libs/vulkan-loader )
"
BDEPEND="
	vulkan? ( media-libs/shaderc )
"

PATCHES=(
	"${FILESDIR}/0001-hip-fix-gfx12-bf16-wmma-with-llvm-23.patch"
	"${FILESDIR}/0002-match-exact-tensor-names-in-llm-config-detection.patch"
	"${FILESDIR}/0003-model-loader-dequantize-int8-tensorwise-when-converting.patch"
)

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

pkg_setup() {
	if use hip; then
		linux-info_pkg_setup
		if linux-info_get_any_version && linux_config_exists; then
			linux_chkconfig_present HSA_AMD_SVM ||
				ewarn "ROCm/HIP requires CONFIG_HSA_AMD_SVM in the kernel."
		fi
	fi
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_unpack() {
	if [[ ${PV} == 9999 ]]; then
		git-r3_src_unpack
	else
		default
		rmdir "${S}/ggml" || die
		mv "${WORKDIR}/ggml-${GGML_COMMIT}" "${S}/ggml" || die
	fi
}

src_prepare() {
	use cuda && cuda_src_prepare

	sed -i -e "s/if(GIT_EXE)/if(NOT DEFINED SDCPP_BUILD_VERSION AND GIT_EXE)/" \
		CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DSD_BUILD_EXAMPLES=ON
		-DSD_BUILD_SHARED_LIBS=ON
		-DSD_BUILD_SHARED_GGML_LIB=ON
		-DSD_SERVER_BUILD_FRONTEND=OFF

		-DSD_WEBP=$(usex webp ON OFF)
		-DSD_USE_SYSTEM_WEBP=$(usex webp ON OFF)
		-DSD_WEBM=$(usex webm ON OFF)
		-DSD_USE_SYSTEM_WEBM=$(usex webm ON OFF)

		-DSD_CUDA=$(usex cuda ON OFF)
		-DSD_HIPBLAS=$(usex hip ON OFF)
		-DSD_VULKAN=$(usex vulkan ON OFF)
		-DSD_OPENCL=$(usex opencl ON OFF)
		-DSD_RPC=ON

		-DCMAKE_INSTALL_INCLUDEDIR="include/stable-diffusion.cpp"
		-DCMAKE_INSTALL_LIBDIR="${EPREFIX}/usr/$(get_libdir)/stable-diffusion.cpp"
		-DCMAKE_INSTALL_RPATH="${EPREFIX}/usr/$(get_libdir)/stable-diffusion.cpp"

		# GGML backend controls
		-DGGML_NATIVE=OFF
		-DGGML_OPENMP=$(usex openmp ON OFF)

		# CPU Flags
		-DGGML_SSE42=$(usex cpu_flags_x86_sse4_2 ON OFF)
		-DGGML_AVX=$(usex cpu_flags_x86_avx ON OFF)
		-DGGML_AVX_VNNI=$(usex cpu_flags_x86_avx_vnni ON OFF)
		-DGGML_AVX2=$(usex cpu_flags_x86_avx2 ON OFF)
		-DGGML_BMI2=$(usex cpu_flags_x86_bmi2 ON OFF)
		-DGGML_AVX512=$(usex cpu_flags_x86_avx512f ON OFF)
		-DGGML_AVX512_VBMI=$(usex cpu_flags_x86_avx512vbmi ON OFF)
		-DGGML_AVX512_VNNI=$(usex cpu_flags_x86_avx512_vnni ON OFF)
		-DGGML_AVX512_BF16=$(usex cpu_flags_x86_avx512_bf16 ON OFF)
		-DGGML_FMA=$(usex cpu_flags_x86_fma3 ON OFF)
		-DGGML_F16C=$(usex cpu_flags_x86_f16c ON OFF)
		-DGGML_AMX_TILE=$(usex cpu_flags_x86_amx_tile ON OFF)
		-DGGML_AMX_INT8=$(usex cpu_flags_x86_amx_int8 ON OFF)
		-DGGML_AMX_BF16=$(usex cpu_flags_x86_amx_bf16 ON OFF)
	)

	if [[ ${PV} != 9999 ]]; then
		mycmakeargs+=(
			-DSDCPP_BUILD_VERSION="${MY_PV}"
			-DSDCPP_BUILD_COMMIT="${MY_COMMIT}"
		)
	fi

	if use openblas ; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS )
	fi

	if use blis ; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=FLAME )
	fi

	if use flexiblas ; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=FlexiBLAS )
	fi

	if use cuda; then
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	if use hip; then
		rocm_use_hipcc
		mycmakeargs+=(
			-DGPU_TARGETS="$(get_amdgpu_flags)"
		)
	fi

	cmake_src_configure
}
