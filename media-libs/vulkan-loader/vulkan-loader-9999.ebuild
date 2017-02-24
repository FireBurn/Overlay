# media-libs/vulkan-base-9999.ebuild

EAPI=6

inherit git-r3 eutils cmake-multilib

DESCRIPTION="Official Vulkan headerfiles, loader, validation layers and sample binaries"
HOMEPAGE="https://vulkan.lunarg.com"
SRC_URI=""
EGIT_REPO_URI="https://github.com/KhronosGroup/Vulkan-LoaderAndValidationLayers.git"

LICENSE="MIT"
IUSE=""
SLOT="0"

KEYWORDS=""

DEPEND="dev-util/cmake
	>=dev-lang/python-3"

src_unpack() {
	git-r3_fetch ${EGIT_REPO_URI}
	git-r3_fetch "https://github.com/KhronosGroup/glslang.git"
	git-r3_fetch "https://github.com/KhronosGroup/SPIRV-Tools.git"
	git-r3_fetch "https://github.com/KhronosGroup/SPIRV-Headers.git"
	git-r3_fetch "https://github.com/google/googletest.git"

	git-r3_checkout ${EGIT_REPO_URI}
	git-r3_checkout https://github.com/KhronosGroup/glslang.git \
		"${S}"/external/glslang
	git-r3_checkout https://github.com/KhronosGroup/SPIRV-Tools.git \
		"${S}"/external/spirv-tools
	git-r3_checkout https://github.com/google/googletest.git \
		"${S}"/external/googletest
	git-r3_checkout https://github.com/KhronosGroup/SPIRV-Headers.git \
		"${S}"/external/spirv-tools/external/spirv-headers
	git-r3_checkout https://github.com/google/googletest.git \
		"${S}"/external/spirv-tools/external/googletest
}

src_prepare() {
	sed -i -e 's#./libVk#libVk#g' "${S}"/layers/linux/*.json
	eapply_user

	multilib_copy_sources
}

multilib_src_configure() {
	einfo "Skipping configure"
}

multilib_src_compile() {
	einfo "Building glslang"
	cd "${BUILD_DIR}"/external/glslang
	cmake -H. -Bbuild
	cd "${BUILD_DIR}"/external/glslang/build	
	emake || die "cannot build glslang"
	make install || die "cannot install glslang"

	einfo "Building SPIRV-Tools"
	cd "${BUILD_DIR}"/external/spirv-tools
	cmake -H. -Bbuild
	cd "${BUILD_DIR}"/external/spirv-tools/build
	emake || die "cannot build SPIRV-Tools"
	
	cd "${BUILD_DIR}"
	cmake	\
		-DCMAKE_SKIP_RPATH=True \
		-DBUILD_WSI_XCB_SUPPORT=ON	\
		-DBUILD_WSI_XLIB_SUPPORT=ON	\
		-DBUILD_WSI_WAYLAND_SUPPORT=ON	\
		-DBUILD_WSI_MIR_SUPPORT=OFF	\
		-DBUILD_VKJSON=OFF		\
		-DBUILD_LOADER=ON		\
		-DBUILD_LAYERS=ON		\
		-DBUILD_DEMOS=ON		\
		-DBUILD_TESTS=ON		\
		-H. -Bbuild
	cd "${BUILD_DIR}"/build
	emake || die "cannot build Vulkan Loader"
}

src_install() {
	mkdir -p "${D}"/etc/vulkan/{icd.d,implicit_layer.d,explicit_layer.d}
	mkdir -p "${D}"/usr/share/vulkan/{icd.d,implicit_layer.d,explicit_layer.d,demos}
	mkdir -p "${D}"/usr/include
	mkdir -p "${D}"/etc/env.d

	insinto /usr/include
	cp -R "${S}"/include/vulkan "${D}"/usr/include

	insinto /usr/share/vulkan/explicit_layer.d
	doins "${S}"/layers/linux/*.json

	dodoc "${S}"/LICENSE.txt

	local VULKAN_LDPATHS=()
	multilib-minimal_src_install
}

multilib_src_install() {
	mkdir -p "${D}"/usr/$(get_libdir)/vulkan/layers

	exeinto /usr/$(get_libdir)/vulkan/layers
	doexe "${BUILD_DIR}"/build/layers/lib*.so*

	dolib.so "${BUILD_DIR}"/build/loader/lib*.so*

	exeinto /usr/share/vulkan/demos
    if multilib_is_native_abi; then
		doexe "${BUILD_DIR}"/build/demos/vulkaninfo
    else
		newexe "${BUILD_DIR}"/build/demos/vulkaninfo vulkaninfo-${ABI}
	fi

	VULKAN_LDPATHS+=( "${EPREFIX}/usr/$(get_libdir)/vulkan" )
	VULKAN_LDPATHS+=( "${EPREFIX}/usr/$(get_libdir)/vulkan/layers" )
}

multilib_src_install_all() {

	cat << EOF > "${D}"/etc/env.d/89vulkan
LDPATH="$( IFS=:; echo "${VULKAN_LDPATHS[*]}" )"
PATH="${EPREFIX}/usr/share/vulkan/demos"
EOF
}
