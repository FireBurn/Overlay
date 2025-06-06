# Copyright 2020-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3 toolchain-funcs xdg

DESCRIPTION="An emulator for Nintendo Switch"
HOMEPAGE="https://yuzu-emu.org"
EGIT_REPO_URI="https://codeberg.org/yuzu-emu/yuzu"
EGIT_SUBMODULES=( '-*' 'dynarmic' 'simpleini' 'sirit' 'tzdb_to_nx' 'externals/nx_tzdb/tzdb_to_nx/externals/tz/tz' 'VulkanMemoryAllocator' 'xbyak' )
# Dynarmic is not intended to be generic, it is tweaked to fit emulated processor
# TODO wait 'xbyak' waiting version bump. see #860816

LICENSE="|| ( Apache-2.0 GPL-2+ ) 0BSD BSD GPL-2+ ISC MIT
	!system-vulkan? ( Apache-2.0 )"
SLOT="0"
KEYWORDS="amd64"
IUSE="+compatibility-list +cubeb discord +qt5 qt6 sdl +system-vulkan test webengine +webservice"

RDEPEND="
	<net-libs/mbedtls-3.1[cmac]
	>=app-arch/zstd-1.5
	>=dev-libs/inih-52
	>=dev-libs/libfmt-11:=
	>=dev-libs/openssl-1.1:=
	>=media-video/ffmpeg-4.3:=
	>=net-libs/enet-1.3
	app-arch/lz4:=
	dev-libs/boost:=[context]
	media-libs/opus
	media-libs/vulkan-loader
	sys-libs/zlib
	virtual/libusb:1
	cubeb? ( media-libs/cubeb )
	qt5? (
		>=dev-qt/qtcore-5.15:5
		>=dev-qt/qtgui-5.15:5
		>=dev-qt/qtmultimedia-5.15:5
		>=dev-qt/qtwidgets-5.15:5
	)
	qt6? (
		>=dev-qt/qtbase-6.6.0:6[gui,widgets]
	)
	sdl? (
		>=media-libs/libsdl2-2.0.18
	)
"
DEPEND="${RDEPEND}
	dev-cpp/cpp-httplib
	dev-cpp/cpp-jwt
	system-vulkan? (
		>=dev-util/spirv-tools-1.3.236
		>=dev-util/vulkan-headers-1.3.236
		>=dev-util/vulkan-utility-libraries-1.3.236
	)
	test? ( <dev-cpp/catch-3:0 )
"
BDEPEND="
	>=dev-cpp/nlohmann_json-3.8.0
	dev-cpp/robin-map
	dev-util/glslang
	discord? ( >=dev-libs/rapidjson-1.1.0 )
"
REQUIRED_USE="|| ( qt5 qt6 sdl ) discord? ( webservice )"
RESTRICT="!test? ( test )"

pkg_setup() {
	if tc-is-gcc; then
		[[ "$(gcc-major-version)" -lt 11 ]] && \
			die "You need gcc version 11 or clang to compile this package"
	fi
}

src_unpack() {
	if use discord; then
		EGIT_SUBMODULES+=('discord-rpc')
	fi

	if use !system-vulkan; then
		EGIT_SUBMODULES+=('Vulkan-Headers' 'Vulkan-Utility-Libraries')
	fi

	if use test; then
		EGIT_SUBMODULES+=('Catch2')
	fi

	git-r3_src_unpack
	# Do not fetch via sources because this file always changes
	#use compatibility-list && curl https://api.yuzu-emu.org/gamedb/ > "${S}"/compatibility_list.json
}

src_prepare() {
	# temporary fix
	sed -i -e '/Werror/d' src/CMakeLists.txt || die

	# Allow skip submodule downloading
	rm .gitmodules || die

	# Unbundle mbedtls
	sed -i -e '/^# mbedtls/,/^endif()/d' externals/CMakeLists.txt || die
	sed -i -e 's/mbedtls/& mbedcrypto mbedx509/' \
		src/dedicated_room/CMakeLists.txt \
		src/core/CMakeLists.txt || die

	# Workaround: GenerateSCMRev fails
	sed -i -e "s/@GIT_BRANCH@/${EGIT_BRANCH:-master}/" \
		-e "s/@GIT_REV@/$(git rev-parse --short HEAD)/" \
		-e "s/@GIT_DESC@/$(git describe --always --long)/" \
		src/common/scm_rev.cpp.in || die

	if ! use discord; then
		sed -i -e '/^if.*discord-rpc/,/^endif()/d' externals/CMakeLists.txt || die
	else
		# Unbundle discord rapidjson
		sed -i -e '/NOT RAPIDJSONTEST/,/endif(NOT RAPIDJSONTEST)/d' \
		-e '/find_file(RAPIDJSON/d' -e 's:\${RAPIDJSON}:"/usr/include/rapidjson":' \
			externals/discord-rpc/CMakeLists.txt || die
	fi

	# Unbundle cubeb
	use cubeb && sed -i '$afind_package(Threads REQUIRED)' CMakeLists.txt || die
	sed -i '/^if.*cubeb/,/^endif()/d' externals/CMakeLists.txt || die

	# Unbundle cpp-httplib
	sed -i -e '/httplib/s/ 0.12//' CMakeLists.txt || die
	sed -i -e '/^# httplib/,/^endif()/d' externals/CMakeLists.txt || die

	# Unbundle enet
	sed -i -e '/^if.*enet/,/^endif()/d' externals/CMakeLists.txt || die
	sed -i -e '/enet\/enet\.h/{s/"/</;s/"/>/}' src/network/network.cpp || die

	# LZ4 temporary fix: https://github.com/yuzu-emu/yuzu/pull/9054/commits/a8021f5a18bc5251aef54468fa6033366c6b92d9
	sed -i 's/lz4::lz4/lz4/' src/common/CMakeLists.txt || die

	# Allow compiling using older glslang
	sed -i -e '/Vulkan/s/313/309/' CMakeLists.txt || die

	cmake_src_prepare
}

src_configure() {
	local -a mycmakeargs=(
		# Libraries are private and rely on circular dependency resolution.
		-DBUILD_SHARED_LIBS=OFF # dynarmic
		-DENABLE_COMPATIBILITY_LIST_DOWNLOAD=$(usex compatibility-list)
		-DENABLE_CUBEB=$(usex cubeb)
		-DENABLE_LIBUSB=ON
		-DENABLE_QT=$(usev qt5 ON || usev qt6 ON || echo OFF )
		-DENABLE_QT_TRANSLATION=$(usev qt5 ON || usev qt6 ON || echo OFF )
		-DENABLE_QT6=$(usex qt6)
		-DENABLE_SDL2=$(usex sdl)
		-DENABLE_WEB_SERVICE=$(usex webservice)
		-DUSE_DISCORD_PRESENCE=$(usex discord)
		-DYUZU_TESTS=$(usex test)
		-DYUZU_USE_EXTERNAL_VULKAN_HEADERS=$(usex system-vulkan no yes)
		-DYUZU_USE_EXTERNAL_VULKAN_UTILITY_LIBRARIES=$(usex system-vulkan no yes)
		-DYUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS=$(usex system-vulkan no yes)
		-DYUZU_USE_EXTERNAL_SDL2=OFF
		-DYUZU_USE_QT_WEB_ENGINE=$(usex webengine)
		-DYUZU_CMD=OFF
		-DYUZU_ROOM=OFF
	)

	cmake_src_configure

	# This would be better in src_unpack but it would be unlinked
	if use compatibility-list; then
		#mv "${S}"/compatibility_list.json "${BUILD_DIR}"/dist/compatibility_list/ || die
		xz --decompress --stdout "${FILESDIR}/gamedb.xz" > "${BUILD_DIR}"/dist/compatibility_list/compatibility_list.json || die
	fi
}
