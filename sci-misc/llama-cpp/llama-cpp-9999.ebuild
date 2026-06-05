# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION="6.3"

inherit cmake cuda rocm linux-info flag-o-matic

DESCRIPTION="Port of Facebook's LLaMA model in C/C++"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

if [[ "${PV}" != "9999" ]]; then
	KEYWORDS="~amd64"
	MY_PV="b${PV#0_pre}"
	LLAMA_UI_VERSION="${MY_PV}"
	S="${WORKDIR}/llama.cpp-${MY_PV}"
	SRC_URI="https://github.com/ggml-org/llama.cpp/archive/refs/tags/${MY_PV}.tar.gz -> ${P}.tar.gz"
else
	inherit git-r3
	KEYWORDS="~amd64"
	EGIT_REPO_URI="https://github.com/ggml-org/llama.cpp.git"

	# Manually update this to a known-good recently published UI version
	# to avoid 404s on bleeding-edge commits and to keep Manifest hashes stable.
	LLAMA_UI_VERSION="b9518"
fi

# Fetch prebuilt UI assets via standard Portage SRC_URI
HF_UI_URI="https://huggingface.co/buckets/ggml-org/llama-ui/resolve/${LLAMA_UI_VERSION}"
SRC_URI+="
	${HF_UI_URI}/index.html -> llama-ui-${LLAMA_UI_VERSION}-index.html
	${HF_UI_URI}/bundle.js -> llama-ui-${LLAMA_UI_VERSION}-bundle.js
	${HF_UI_URI}/bundle.css -> llama-ui-${LLAMA_UI_VERSION}-bundle.css
	${HF_UI_URI}/loading.html -> llama-ui-${LLAMA_UI_VERSION}-loading.html
"

LICENSE="MIT"
SLOT="0"
CPU_FLAGS_X86=( avx avx2 f16c )
IUSE="curl openblas +openmp blis hip cuda opencl vulkan"
REQUIRED_USE="?? ( openblas blis )"

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
	if [[ "${PV}" == "9999" ]]; then
		# Check if our pinned UI version is lagging behind the live repo
		local current_tag=$(git describe --tags --match 'b*' --abbrev=0 2>/dev/null)
		if [[ -n "${current_tag}" ]]; then
			local current_num=${current_tag#b}
			local used_num=${LLAMA_UI_VERSION#b}
			if [[ "${current_num}" -gt 0 && "${used_num}" -gt 0 ]]; then
				local diff=$(( current_num - used_num ))
				if [[ ${diff} -gt 2 ]]; then
					ewarn "======================================================================"
					ewarn "WARNING: llama.cpp upstream is at ${current_tag}, but this ebuild is"
					ewarn "using UI assets from ${LLAMA_UI_VERSION}."
					ewarn ""
					ewarn "Please update LLAMA_UI_VERSION='${current_tag}' in the ebuild"
					ewarn "and run 'ebuild llama-cpp-9999.ebuild manifest' to refresh the UI."
					ewarn "======================================================================"
				fi
			fi
		fi
	fi

	# Copy the UI assets downloaded by Portage into the location CMake expects.
	# Upstream's ui-assets.cmake checks for these files in ${UI_SOURCE_DIR}/dist
	# (which resolves to tools/ui/dist in the source tree). By placing them here,
	# we circumvent the network-based Hugging Face download attempt during the build.
	local ui_dir="${S}/tools/ui/dist"
	mkdir -p "${ui_dir}" || die
	cp "${DISTDIR}/llama-ui-${LLAMA_UI_VERSION}-index.html" "${ui_dir}/index.html" || die
	cp "${DISTDIR}/llama-ui-${LLAMA_UI_VERSION}-bundle.js" "${ui_dir}/bundle.js" || die
	cp "${DISTDIR}/llama-ui-${LLAMA_UI_VERSION}-bundle.css" "${ui_dir}/bundle.css" || die
	cp "${DISTDIR}/llama-ui-${LLAMA_UI_VERSION}-loading.html" "${ui_dir}/loading.html" || die

	use cuda && cuda_src_prepare

	cmake_src_prepare
}

src_configure() {
	# Force enable the Web UI macro for the server, as upstream's recent CMake
	# refactoring (e.g. PR #23511, #22937) fails to propagate this definition
	# to the shared server implementation library on Linux, resulting in a 404.
	append-cppflags -DLLAMA_BUILD_UI=1 -DLLAMA_BUILD_WEBUI=1

	local mycmakeargs=(
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_BUILD_UI=ON
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
		-DGGML_NATIVE=0	# don't set march
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
		mycmakeargs+=(
			-DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS
		)
	fi

	if use blis ; then
		mycmakeargs+=(
			-DGGML_BLAS=ON -DGGML_BLAS_VENDOR=FLAME
		)
	fi

	if use cuda; then
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
		# tries to recreate dev symlinks
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

src_install() {
	cmake_src_install
	dobin "${BUILD_DIR}/bin/rpc-server"

	# avoid clashing with whisper.cpp
	rm -rf "${ED}/usr/include"
}
