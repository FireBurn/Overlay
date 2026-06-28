# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION="6.3"

inherit cmake cuda rocm linux-info flag-o-matic git-r3

DESCRIPTION="Port of Facebook's LLaMA model in C/C++ (Live Source with UI Build)"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"
EGIT_REPO_URI="https://github.com/ggml-org/llama.cpp.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="curl openblas +openmp blis hip cuda opencl vulkan"

# We must restrict the network sandbox because 'npm install' needs to
# fetch frontend dependencies during the src_compile phase.
RESTRICT="network-sandbox"

# Build-time dependencies
BDEPEND="
	net-libs/nodejs[npm]
	virtual/pkgconfig
"

CDEPEND="
	curl? ( net-misc/curl:= )
	openblas? ( sci-libs/openblas:= )
	openmp? ( llvm-runtimes/openmp:= )
	blis? ( sci-libs/blis:= )
	hip? ( >=dev-util/hip-6.3:=
		>=sci-libs/hipBLAS-6.3:=
	)
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
"
DEPEND="${CDEPEND}
	opencl? ( dev-util/opencl-headers )
	vulkan? ( dev-util/vulkan-headers )
"
RDEPEND="${CDEPEND}
	dev-python/numpy
	opencl? ( dev-libs/opencl-icd-loader )
	vulkan? ( media-libs/vulkan-loader )
"

pkg_setup() {
	if use hip; then
		linux-info_pkg_setup
		if linux-info_get_any_version && linux_config_exists; then
			if ! linux_chkconfig_present HSA_AMD_SVM; then
				ewarn "To use ROCm/HIP, you need to have HSA_AMD_SVM option enabled in your kernel."
			fi
		fi
	fi
}

src_prepare() {
	use cuda && cuda_src_prepare
	cmake_src_prepare
}

src_configure() {
	# Force enable the Web UI macros
	append-cppflags -DLLAMA_BUILD_UI=1 -DLLAMA_BUILD_WEBUI=1

	local mycmakeargs=(
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_BUILD_UI=ON
		# Point CMake to the directory where we will build the UI assets
		-DUI_SOURCE_DIR="${S}/tools/ui"
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
		-DGGML_NATIVE=0
		-DGGML_RPC=ON
		-DLLAMA_CURL=$(usex curl ON OFF)
		-DBUILD_NUMBER="1"
		-DGGML_CUDA=$(usex cuda ON OFF)
		-DGGML_OPENCL=$(usex opencl ON OFF)
		-DGGML_OPENMP=$(usex openmp ON OFF)
		-DGGML_VULKAN=$(usex vulkan ON OFF)

		# avoid clashing with whisper.cpp
		-DCMAKE_INSTALL_LIBDIR="${EPREFIX}/usr/$(get_libdir)/llama.cpp"
		-DCMAKE_INSTALL_RPATH="${EPREFIX}/usr/$(get_libdir)/llama.cpp"
	)

	if use openblas ; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS )
	fi

	if use blis ; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=FLAME )
	fi

	if use cuda; then
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	if use hip; then
		rocm_use_hipcc
		mycmakeargs+=(
			-DGGML_HIP=ON -DAMDGPU_TARGETS=$(get_amdgpu_flags)
		)
	fi

	cmake_src_configure
}

src_compile() {
	# 1. Build the Web UI assets from source
	einfo "Building Web UI assets using npm..."
	pushd "${S}/tools/ui" > /dev/null || die

	# Clean any stale build artifacts
	rm -rf dist node_modules || die

	# Install JS dependencies and run the build (Vite/SvelteKit)
	# This generates the /dist folder CMake expects.
	npm install || die
	npm run build || die

	popd > /dev/null || die

	# 2. Run the standard C++ build
	cmake_src_compile
}

src_install() {
	cmake_src_install
	dobin "${BUILD_DIR}/bin/ggml-rpc-server"
}
