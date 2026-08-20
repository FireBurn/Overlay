# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

EGIT_REPO_URI="https://github.com/FireBurn/Q2RTX.git"
EGIT_SUBMODULES=( '-*' 'extern/stb' 'extern/tinyobjloader-c' )
RELEASE_VER="1.8.0"

DESCRIPTION="NVIDIA's implementation of RTX ray-tracing in Quake II"
HOMEPAGE="https://github.com/NVIDIA/Q2RTX"
SRC_URI="
	https://github.com/NVIDIA/Q2RTX/releases/download/v${RELEASE_VER}/q2rtx-${RELEASE_VER}-linux.tar.gz
"

LICENSE="GPL-2 MIT all-rights-reserved"
SLOT="0"
RESTRICT="bindist mirror"
KEYWORDS="~amd64"

DEPEND="
	dev-util/vulkan-headers
	media-libs/vulkan-loader
	media-libs/libsdl2
	media-libs/openal
	net-misc/curl
	virtual/zlib
"

BDEPEND="
	app-arch/7zip
	dev-util/glslang
	dev-util/spirv-tools
"

RDEPEND="
	${DEPEND}
"

src_unpack() {
	git-r3_src_unpack

	unpack q2rtx-${RELEASE_VER}-linux.tar.gz
}

src_prepare() {
	cmake_src_prepare
	einfo "${P}"
	einfo "${S}"

	local release_base=${WORKDIR}/${PN}/baseq2

	[[ -f ${release_base}/blue_noise.pkz ]] || die "missing blue_noise.pkz"
	[[ -f ${release_base}/q2rtx_media.pkz ]] || die "missing q2rtx_media.pkz"
	[[ -f ${release_base}/pak0.pak ]] || die "missing shareware pak0.pak"
	[[ -d ${release_base}/players ]] || die "missing shareware player models"
	for fsr4_model in native quality balanced performance ultraperf drs; do
		local fsr4_prefix=${S}/baseq2/fsr4_shaders/fsr4_model_v07_i8_${fsr4_model}
		[[ -f ${fsr4_prefix}_initializers.bin ]] ||
			die "missing FSR4 v07 ${fsr4_model} initializer"
		[[ -f ${fsr4_prefix}_pre_weights.bin ]] ||
			die "missing FSR4 v07 ${fsr4_model} pre-pass weights"
	done
	[[ -f ${S}/baseq2/fsr4_shaders/LICENSE-FSR4-v07.txt ]] || die "missing FSR4 v07 asset notice"

	cp -p "${release_base}/blue_noise.pkz" "${S}/baseq2/" || die
	# The checkout deliberately omits NVIDIA's large media tree. The packaging
	# script updates only the source-controlled menu/config entries in this
	# release archive, preserving the original textures/models/audio.
	cp -p "${release_base}/q2rtx_media.pkz" "${S}/baseq2/" || die
	mkdir -p "${S}/baseq2/shareware" || die
	cp -p "${release_base}/pak0.pak" "${S}/baseq2/shareware/" || die
	cp -a "${release_base}/players" "${S}/baseq2/shareware/" || die
}

src_configure() {
	local mycmakeargs=(
		-DCONFIG_LINUX_PACKAGING_SUPPORT=ON
		-DCONFIG_LINUX_PACKAGING_SKIP_PKZ=OFF
		-DCONFIG_BUILD_GLSLANG=OFF
		-DCONFIG_VKPT_RENDERER=ON
		-DCONFIG_VKPT_FSR3=ON
		# The complete older source-v07 FSR4 graph and model asset pairs are
		# versioned with manifest hashes and an upstream MIT asset notice.
		-DCONFIG_VKPT_INSTALL_FSR4_V07_ASSETS=ON
		-DFFX_VK_PORTABLE_BUILD_FSR3_3_1_5_SCAFFOLD=ON
		-DUSE_SYSTEM_ZLIB=ON
		-DUSE_SYSTEM_OPENAL=ON
		-DUSE_SYSTEM_CURL=ON
		-DUSE_SYSTEM_SDL2=ON
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	local game_root=${ED}/usr/share/quake2rtx
	[[ -x ${ED}/usr/bin/q2rtx ]] || die "launcher was not installed to /usr/bin"
	[[ -x ${ED}/usr/bin/q2rtxded ]] || die "dedicated server was not installed to /usr/bin"
	[[ -x ${game_root}/bin/q2rtx ]] || die "client binary was not installed"
	[[ -x ${game_root}/bin/find-retail-paks.sh ]] || die "retail PAK importer was not installed"
	[[ -f ${game_root}/baseq2/q2rtx_media.pkz ]] || die "media archive was not installed"
	[[ -f ${game_root}/baseq2/q2rtx.menu ]] || die "versioned menu override was not installed"
	[[ -f ${game_root}/baseq2/shaders.pkz ]] || die "shader archive was not installed"
	[[ -f ${game_root}/baseq2/blue_noise.pkz ]] || die "blue-noise asset was not installed"
	[[ -f ${game_root}/baseq2/shareware/pak0.pak ]] || die "shareware PAK was not installed"
	[[ -d ${game_root}/baseq2/shareware/players ]] || die "shareware player models were not installed"
	for fsr4_model in native quality balanced performance ultraperf drs; do
		local fsr4_prefix=${game_root}/baseq2/fsr4_shaders/fsr4_model_v07_i8_${fsr4_model}
		[[ -f ${fsr4_prefix}_initializers.bin ]] ||
			die "FSR4 v07 ${fsr4_model} initializer was not installed"
		[[ -f ${fsr4_prefix}_pre_weights.bin ]] ||
			die "FSR4 v07 ${fsr4_model} pre-pass weights were not installed"
	done
	[[ -f ${game_root}/baseq2/fsr4_shaders/LICENSE-FSR4-v07.txt ]] || die "FSR4 v07 asset notice was not installed"

	# FSR3 and analytical FSR3 frame generation are compiled into the client.
	# The complete older source-v07 FSR4 graph/model set is installed above.
}

pkg_postinst() {
	elog "The shareware data is installed. Retail PAKs, players, and music are optional."
	elog "On first launch, choose the retail import prompt or copy them to:"
	elog "  \${XDG_DATA_HOME:-\${HOME}/.local/share}/quake2rtx/baseq2"
	elog "Native Vulkan FSR3 upscaling and analytical FSR3 frame generation are built in."
	ewarn "Experimental FSR4 v07 is installed with its source-v07 model assets; it is not AMD FSR 4.1.1."
}
