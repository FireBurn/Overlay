# media-libs/vulkan-base-9999.ebuild

EAPI=6

inherit git-r3

DESCRIPTION="Official Vulkan headerfiles, loader, validation layers and sample binaries"
HOMEPAGE="https://vulkan.lunarg.com"
SRC_URI=""
EGIT_REPO_URI="https://github.com/KhronosGroup/Vulkan-LoaderAndValidationLayers.git"

LICENSE="MIT"
IUSE=""
SLOT="0"

KEYWORDS="~amd64"

DEPEND="dev-util/cmake
	>=dev-lang/python-3"

src_unpack() {
	git-r3_fetch "https://github.com/KhronosGroup/glslang.git"
	git-r3_fetch "https://github.com/KhronosGroup/SPIRV-Tools.git"
	git-r3_fetch ${EGIT_REPO_URI}

	git-r3_checkout https://github.com/KhronosGroup/glslang.git \
		"${S}"/glslang
	git-r3_checkout https://github.com/KhronosGroup/SPIRV-Tools.git \
		"${S}"/spirv-tools
	git-r3_checkout ${EGIT_REPO_URI} "${S}"/sdk
}

src_prepare() {
	sed -i -e 's#./libVk#libVk#g' "${S}"/sdk/layers/linux/*.json
	eapply_user
}

src_compile() {
	einfo "Building glslang"
	cd "${S}"/glslang
	cmake -H. -Bbuild
	cd "${S}"/glslang/build	
	emake || die "cannot build glslang"
	make install || die "cannot install glslang"

	einfo "Building SPIRV-Tools"
	cd "${S}"/spirv-tools
	cmake -H. -Bbuild
	cd "${S}"/spirv-tools/build
	emake || die "cannot build SPIRV-Tools"
	
	cd "${S}"/sdk
	cmake	\
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
	cd "${S}"/sdk/build
	emake || die "cannot build Vulkan Loader"
}

src_install() {
	mkdir -p "${D}"/etc/vulkan/{icd.d,implicit_layer.d,explicit_layer.d}
	mkdir -p "${D}"/usr/share/vulkan/{icd.d,implicit_layer.d,explicit_layer.d}
	mkdir -p "${D}"/usr/lib64/vulkan/layers
	mkdir -p "${D}"/usr/bin
	mkdir -p "${D}"/usr/include
	mkdir -p "${D}"/etc/env.d

	#rename the tri and cube examples
	mv "${S}"/sdk/build/demos/cube "${S}"/sdk/build/demos/vulkancube
	mv "${S}"/sdk/build/demos/tri "${S}"/sdk/build/demos/vulkantri
	dobin "${S}"/sdk/build/demos/vulkan{info,cube,tri}
	#dobin "${S}"/spirv-tools/build/spirv-*

	insinto /usr/include
	cp -R "${S}"/sdk/include/vulkan "${D}"/usr/include

	dolib.so "${S}"/sdk/build/loader/lib*.so*

	exeinto /usr/$(get_libdir)/vulkan
	doexe "${S}"/sdk/build/layers/liblayer*.so*
	exeinto /usr/$(get_libdir)/vulkan/layers
	doexe "${S}"/sdk/build/layers/libVk*.so*

	insinto /usr/share/vulkan/explicit_layer.d
	doins "${S}"/sdk/layers/linux/*.json

	docinto /
	dodoc "${S}"/sdk/LICENSE.txt

	# create an entry for the newly created vulkan libs
	cat << EOF > "${D}"/etc/env.d/89vulkan
LDPATH="/usr/$(get_libdir)/vulkan;/usr/$(get_libdir)/vulkan/layers"
EOF
}

pkg_postinst() {
	env-update
}

pkg_postrm() {
	env-update
}
