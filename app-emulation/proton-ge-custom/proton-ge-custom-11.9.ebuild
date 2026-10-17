# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit edo python-any-r1 wine

GE_TAG=GE-Proton${PV/./-}

# the commit Proton's prep script reverts to bring back the configure files
WINE_REVERT_COMMIT=e813ca5771658b00875924ab88d525322e50d39f

VKD3D_PROTON_COMMIT=2230755878b01993b4b82d0ac0c0624f3ab4d333

# Proton's submodules at the commits the GE-Proton11-9 tag pins, and theirs
# in turn: "path repository commit". Parents come before what lives under them.
PROTON_TREES=(
	"wine ValveSoftware/wine 981e2f0b9007fd70a6e0ed6119cb18f4164e26f9"
	"wine-staging wine-staging/wine-staging 6cc805ea57132eeaf44764e9213823c9b8d0d300"
	"dxvk doitsujin/dxvk 71ec7b5be6c517db39bcca4d38f38a63f6ddbc56"
	"vkd3d-proton HansKristian-Work/vkd3d-proton 2230755878b01993b4b82d0ac0c0624f3ab4d333"
	"d7vk WinterSnowfall/d7vk d8363d1a690894dd01ca72da24d2f4c045a4f2b3"
	"dxvk-nvapi jp7677/dxvk-nvapi 0f26995d8126617d4d99f62c9571715fc7765da1"
	"Vulkan-Headers KhronosGroup/Vulkan-Headers 36872f9062b17b1a30b8ed1d81ca5ea6bb608a72"
	"openvr ValveSoftware/openvr 91825305130f446f82054c1ec3d416321ace0072"
	"protonfixes open-wine-components/umu-protonfixes e89ce7b43800b0df4c37015239d64952fb42ed8b"
	"vklayers/low_latency_layer Korthos-Software/low_latency_layer 4e7fe12b797d89be07919acf3d2df5cda3f4d89f"
	"dxvk/include/native/directx Joshua-Ashton/mingw-directx-headers 9df86f2341616ef1888ae59919feaa6d4fad693d"
	"dxvk/include/spirv KhronosGroup/SPIRV-Headers 04f10f650d514df88b76d25e83db360142c7b174"
	"dxvk/include/vulkan KhronosGroup/Vulkan-Headers 6802bb4733b63ed5efd3adb308a6c885ef180ea1"
	"dxvk/subprojects/dxbc-spirv doitsujin/dxbc-spirv ecb8308fe03fcad695a6ebdacbef6e7f61e77484"
	"dxvk/subprojects/dxbc-spirv/submodules/spirv_headers KhronosGroup/SPIRV-Headers c8ad050fcb29e42a2f57d9f59e97488f465c436d"
	"dxvk/subprojects/libdisplay-info doitsujin/libdisplay-info 275e6459c7ab1ddd4b125f28d0440716e4888078"
	"vkd3d-proton/khronos/SPIRV-Headers KhronosGroup/SPIRV-Headers f88a2d766840fc825af1fc065977953ba1fa4a91"
	"vkd3d-proton/khronos/Vulkan-Headers KhronosGroup/Vulkan-Headers ee2ec5fd83dafce291024683b50dc89219333076"
	"vkd3d-proton/subprojects/dxil-spirv HansKristian-Work/dxil-spirv ab47c3df1a4746f36c958f0262bc9e314eb566eb"
	"vkd3d-proton/subprojects/dxil-spirv/subprojects/dxbc-spirv doitsujin/dxbc-spirv 8dae2d8573af08378c6059aca3d5987da99d20b5"
	"vkd3d-proton/subprojects/dxil-spirv/subprojects/dxbc-spirv/submodules/spirv_headers KhronosGroup/SPIRV-Headers c8ad050fcb29e42a2f57d9f59e97488f465c436d"
	"vkd3d-proton/subprojects/dxil-spirv/third_party/SPIRV-Cross KhronosGroup/SPIRV-Cross be71ee8c12cd7dc5ca8fa9581f708c2e8561fe2a"
	"vkd3d-proton/subprojects/dxil-spirv/third_party/SPIRV-Tools KhronosGroup/SPIRV-Tools 199cb207b911501ddd76dcddf100a6e21c15ef23"
	"vkd3d-proton/subprojects/dxil-spirv/third_party/spirv-headers KhronosGroup/SPIRV-Headers c63848ecf2200425511319fd8bf2c17b751e501e"
	"d7vk/include/native/directx Joshua-Ashton/mingw-directx-headers 9df86f2341616ef1888ae59919feaa6d4fad693d"
	"d7vk/include/spirv KhronosGroup/SPIRV-Headers 04f10f650d514df88b76d25e83db360142c7b174"
	"d7vk/include/vulkan KhronosGroup/Vulkan-Headers 6802bb4733b63ed5efd3adb308a6c885ef180ea1"
	"d7vk/subprojects/dxbc-spirv doitsujin/dxbc-spirv ecb8308fe03fcad695a6ebdacbef6e7f61e77484"
	"d7vk/subprojects/dxbc-spirv/submodules/spirv_headers KhronosGroup/SPIRV-Headers c8ad050fcb29e42a2f57d9f59e97488f465c436d"
	"d7vk/subprojects/libdisplay-info doitsujin/libdisplay-info 275e6459c7ab1ddd4b125f28d0440716e4888078"
	"dxvk-nvapi/external/DirectX-Headers microsoft/DirectX-Headers ea2799ce66647c69710a81338e828b19973e0370"
	"dxvk-nvapi/external/Vulkan-Headers KhronosGroup/Vulkan-Headers e3b1eec08173d6b825cd3ac88c885a63b621504a"
	"dxvk-nvapi/external/nvapi NVIDIA/nvapi 87dca625e83fd89a983e19b904e5f3a580da90d2"
	"dxvk-nvapi/external/vkroots misyltoad/vkroots ee76e620798612c52fb8dcc32a1058a0a3538930"
)

SRC_URI="
	https://github.com/GloriousEggroll/proton-ge-custom/archive/refs/tags/${GE_TAG}.tar.gz
		-> ${P}.tar.gz
	https://github.com/ValveSoftware/wine/commit/${WINE_REVERT_COMMIT}.patch
		-> ${PN}-valve-wine-${WINE_REVERT_COMMIT::10}.patch
"
for _tree in "${PROTON_TREES[@]}"; do
	_tree=( ${_tree} )
	SRC_URI+="
	https://github.com/${_tree[1]}/archive/${_tree[2]}.tar.gz
		-> ${PN}-${_tree[1]//\//-}-${_tree[2]::10}.tar.gz"
done
unset _tree
KEYWORDS="-* ~amd64"

DESCRIPTION="GloriousEggroll's Proton fork: Valve's Wine with staging and game fixes"
HOMEPAGE="https://github.com/GloriousEggroll/proton-ge-custom"

PROTON_S=${WORKDIR}/proton
S=${PROTON_S}/wine

LICENSE="LGPL-2.1+ BSD BSD-2 IJG MIT OPENLDAP ZLIB libpng2 public-domain"
SLOT="0"
IUSE="
	+X +alsa cups +dbus +ffmpeg +fontconfig opencl +opengl pcap
	pulseaudio +sdl +ssl +truetype udev usb v4l +vulkan wayland
	xinerama
"
REQUIRED_USE="
	X? ( truetype )
	opengl? ( || ( X wayland ) )
	udev? ( sdl )
"
RESTRICT="test"

WINE_DLOPEN_DEPEND="
	X? (
		x11-libs/libXcomposite[${WINE_USEDEP}]
		x11-libs/libXcursor[${WINE_USEDEP}]
		x11-libs/libXfixes[${WINE_USEDEP}]
		x11-libs/libXi[${WINE_USEDEP}]
		x11-libs/libXrandr[${WINE_USEDEP}]
		x11-libs/libXrender[${WINE_USEDEP}]
		x11-libs/libXxf86vm[${WINE_USEDEP}]
		xinerama? ( x11-libs/libXinerama[${WINE_USEDEP}] )
	)
	cups? ( net-print/cups[${WINE_USEDEP}] )
	dbus? ( sys-apps/dbus[${WINE_USEDEP}] )
	fontconfig? ( media-libs/fontconfig[${WINE_USEDEP}] )
	opencl? ( virtual/opencl[${WINE_USEDEP}] )
	opengl? ( media-libs/libglvnd[X?,${WINE_USEDEP}] )
	sdl? ( media-libs/libsdl2[haptic,joystick,${WINE_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${WINE_USEDEP}] )
	truetype? ( media-libs/freetype[${WINE_USEDEP}] )
	v4l? ( media-libs/libv4l[${WINE_USEDEP}] )
	vulkan? ( media-libs/vulkan-loader[X?,wayland?,${WINE_USEDEP}] )
"
WINE_COMMON_DEPEND="
	${WINE_DLOPEN_DEPEND}
	X? (
		x11-libs/libX11[${WINE_USEDEP}]
		x11-libs/libXext[${WINE_USEDEP}]
	)
	alsa? ( media-libs/alsa-lib[${WINE_USEDEP}] )
	media-libs/openxr[${WINE_USEDEP}]
	ffmpeg? ( media-video/ffmpeg:=[${WINE_USEDEP}] )
	pcap? ( net-libs/libpcap[${WINE_USEDEP}] )
	pulseaudio? ( media-libs/libpulse[${WINE_USEDEP}] )
	udev? ( virtual/libudev:=[${WINE_USEDEP}] )
	usb? ( dev-libs/libusb:1[${WINE_USEDEP}] )
	wayland? (
		dev-libs/wayland[${WINE_USEDEP}]
		x11-libs/libxkbcommon[${WINE_USEDEP}]
	)
"
RDEPEND="
	${WINE_COMMON_DEPEND}
	app-emulation/wine-desktop-common
	media-fonts/liberation-fonts
"
DEPEND="
	${WINE_COMMON_DEPEND}
	>=sys-kernel/linux-headers-6.14
	X? ( x11-base/xorg-proto )
	opencl? ( dev-util/opencl-headers )
"

BDEPEND="
	media-fonts/liberation-fonts
	dev-build/cmake
	dev-util/llvm-mingw64[x86-64-pe,i686-pe]
	${PYTHON_DEPS}
	app-arch/zstd
	dev-build/meson
	dev-build/ninja
	dev-util/glslang
	dev-vcs/git
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	dev-lang/nasm
"

src_unpack() {
	local tree
	unpack ${P}.tar.gz
	mv proton-ge-custom-* proton || die

	for tree in "${PROTON_TREES[@]}"; do
		tree=( ${tree} )
		mkdir -p "proton/${tree[0]}" || die
		tar -xzf "${DISTDIR}/${PN}-${tree[1]//\//-}-${tree[2]::10}.tar.gz" \
			--strip-components=1 -C "proton/${tree[0]}" || die
	done
}

src_prepare() {
	cd "${PROTON_S}" || die

	# Upstream's script expects Git checkouts of every submodule. These are
	# release archives, so what it asks Git for is dropped and the one
	# revert it makes is applied as a patch.
	awk -v revert="${DISTDIR}/${PN}-valve-wine-${WINE_REVERT_COMMIT::10}.patch" '
		cont { cont = ($0 ~ /\\$/); next }
		/^[[:space:]]*git (reset|clean|checkout)/ { cont = ($0 ~ /\\$/); next }
		/git revert --no-commit/ { print "    patch -RNp1 < \"" revert "\""; next }
		/bash \.\/patches\/wine-mono\/prepare\.sh/ { next }
		/^[[:space:]]*autoreconf -f/ { next }
		/^[[:space:]]*\.\/tools\/make_requests/ { next }
		{ print }
	' patches/protonprep-valve-staging.sh > "${T}"/protonprep.sh || die

	edo bash "${T}"/protonprep.sh

	# libc++'s <array> reaches <wchar.h> after Wine's headers have defined
	# wcsncpy as an error, so the C header goes first
	sed -i '/^EXTRADEFS/s/=/= -include wchar.h/' \
		lsteamclient/Makefile.in vrclient_x64/Makefile.in || die

	# DXVK refuses AVX on Windows because GCC does not realign the stack for
	# 32-byte spills, which clang does
	sed -i '/defined(_WIN32) && (defined(__AVX__) || defined(__AVX2__))/s/#if /#if !defined(__clang__) \&\& /' \
		dxvk/src/util/util_bit.h d7vk/src/util/util_bit.h || die

	# OpenVR's Windows code assumes MSVC wherever it sees _WIN32
	sed -i 's/^#if defined( _WIN32 ) && _MSC_VER < 1800$/#if defined( _WIN32 ) \&\& defined( _MSC_VER ) \&\& _MSC_VER < 1800/' \
		openvr/src/vrcore/strtools_public.h || die

	# libstdc++'s <limits> undefines the max macro of Wine's headers, libc++
	# leaves it alone
	sed -i 's/std::max(/(std::max)(/' lsteamclient/unixlib.cpp || die

	cd "${S}" || die
	wine_src_prepare

	# generated files Proton's build makes after patching
	XDG_CACHE_HOME=${T} edo dlls/winevulkan/make_vulkan -x vk.xml -X video.xml
	edo tools/make_specfiles
}

src_configure() {
	local wineconfargs=(
		--disable-tests
		--disable-mshtml
		--disable-mscoree

		$(use_with X x)
		$(use_with alsa)
		--without-capi
		$(use_with cups)
		$(use_with dbus)
		$(use_with ffmpeg)
		$(use_with fontconfig)
		--without-hwloc
		# libunwind's context is a ucontext_t only in the GNU one
		--without-unwind
		$(use_with opencl)
		$(use_with opengl)
		--without-oss
		$(use_with pcap)
		$(use_with pulseaudio pulse)
		$(use_with sdl)
		$(use_with ssl gnutls)
		$(use_with truetype freetype)
		$(use_with udev)
		$(use_with usb)
		$(use_with v4l v4l2)
		$(use_with vulkan)
		$(use_with wayland)
		$(use_with xinerama)

		# Everything below one directory, bin/ lib/wine/ and share/wine/
		# as in a Proton tree, so that what is installed can be tarred up
		# and used from anywhere: Wine finds the rest relative to itself.
		--libdir="${EPREFIX}"/usr/lib/${P}/lib
		--datadir="${EPREFIX}"/usr/lib/${P}/share
		--mandir="${EPREFIX}"/usr/lib/${P}/share/man
	)

	# Wine's PE modules, DXVK and the rest all want one compiler, and that is
	# llvm-mingw's clang, not whichever mingw gcc a host happens to carry
	PATH=${BROOT}/usr/lib/llvm-mingw64/bin:${PATH}
	wine_src_configure
}

# Builds a Direct3D component from its tree with the cross compiler wine's
# own PE build uses, the way Proton's make rules do: one meson build per
# architecture, the DLLs going to wine/<name>/<arch>-windows.
#   $1 name, $2 directory, $3 arch (x86_64 or i386), the rest meson arguments
_proton_meson_pe() {
	local name=$1 dir=$2 arch=$3
	shift 3

	local triple cpu
	case ${arch} in
		x86_64) triple=x86_64-w64-mingw32 cpu=x86_64 ;;
		i386) triple=i686-w64-mingw32 cpu=x86 ;;
		*) die "unknown architecture ${arch}" ;;
	esac

	local bdir=${WORKDIR}/build-${name}-${arch}
	local dest=${WORKDIR}/components
	local flags="-O3 -march=native -fwrapv -fno-strict-aliasing -ffunction-sections -fdata-sections -fno-omit-frame-pointer"
	cat > "${bdir}.cross" <<-EOF || die
		[binaries]
		c = '${triple}-clang'
		cpp = '${triple}-clang++'
		ar = '${triple}-ar'
		strip = '${triple}-strip'
		windres = '${triple}-windres'
		widl = '${S}/tools/widl/widl'

		[properties]
		needs_exe_wrapper = true
		c_args = ['${flags// /\', \'}']
		cpp_args = ['${flags// /\', \'}']
		c_link_args = ['-fuse-ld=lld']
		cpp_link_args = ['-fuse-ld=lld']

		[host_machine]
		system = 'windows'
		cpu_family = '${cpu}'
		cpu = '${cpu}'
		endian = 'little'
	EOF

	edo meson setup "${bdir}" "${PROTON_S}/${dir}" \
		--prefix="${dest}" \
		--libdir=lib \
		--bindir="${dest}/lib/wine/${name}/${arch//i386/i386}-windows" \
		--buildtype=plain \
		--cross-file="${bdir}.cross" \
		-Db_lto=true -Db_lto_mode=thin \
		--strip \
		"$@"
	edo ninja -C "${bdir}" install
}

# Builds one of Proton's Wine modules (lsteamclient and the like) with Wine's
# own makedep, in a tree of its own beside the finished Wine build, as the
# make rules of Proton do. With the wow64 build the PE side comes out for
# both x86_64 and i386 and the Unix side for x86_64 only.
#   $1 name, $2 source directory
_proton_wine_module() {
	local name=$1 dir=$2
	local obj=${WORKDIR}/build-${name}
	local dest=${WORKDIR}/components

	mkdir -p "${obj}" || die
	: > "${obj}"/config.status
	# An absolute SUBDIRS entry marks the module as external to Wine, which
	# keeps it from failing on includes of its own bundled library, and
	# makes its files appear as dlls/<last component>.
	ln -sfn "${S}"/include "${obj}"/include || die
	ln -sfn "${PROTON_S}/${dir}" "${obj}/src-${name}" || die
	mkdir -p "${obj}"/dlls || die
	ln -sfn "${PROTON_S}/${dir}" "${obj}/dlls/src-${name}" || die

	cat > "${T}/${name}.sed" <<-EOF || die
		1 i\\UNIX_LIBS = ${S}/dlls/ntdll/ntdll.so\\n
		/^all:\$/,\$c all:
		/^SUBDIRS/,/[^\\\\]\$/c SUBDIRS = ${obj}/src-${name}
		/^TOP_INSTALL_DEV/c TOP_INSTALL_DEV =
		/^TOP_INSTALL_LIB/c TOP_INSTALL_LIB = dlls/src-${name}
		/^srcdir/a objdir = ${S}
		/^prefix/c prefix = ${dest}
		/^libdir/c libdir = ${dest}/lib
		/^toolsdir/c toolsdir = ${S}
		/^x86_64_CFLAGS/s|=|= -I${PROTON_S}/Vulkan-Headers/include|
		/^i386_CFLAGS/s|=|= -I${PROTON_S}/Vulkan-Headers/include|
		/^CFLAGS/s|=|= -I${PROTON_S}/Vulkan-Headers/include|
		/^x86_64_LDFLAGS/s|=|= -L${S}/dlls/xinput1_3/x86_64-windows|
		/^i386_LDFLAGS/s|=|= -L${S}/dlls/xinput1_3/i386-windows|
	EOF
	sed -f "${T}/${name}.sed" "${S}"/Makefile > "${obj}"/Makefile || die

	( cd "${obj}" && edo "${S}"/tools/makedep ) || die
	# makedep names ntdll for the Unix link as well as giving its path
	sed -i 's/\(\.o\) -lntdll \\$/\1 \\/' "${obj}"/Makefile || die
	emake -C "${obj}"
	emake -C "${obj}" install
}

src_compile() {
	wine_src_compile

	local arch
	PATH=${BROOT}/usr/lib/llvm-mingw64/bin:${PATH}

	# there is no Git to stamp the version with
	sed -i "s#@VCS_TAG@#${PV}#" \
		"${PROTON_S}"/dxvk/version.h.in \
		"${PROTON_S}"/d7vk/version.h.in \
		"${PROTON_S}"/vkd3d-proton/vkd3d_version.h.in || die
	# the build number is a hexadecimal constant
	sed -i "s#@VCS_TAG@#${VKD3D_PROTON_COMMIT::15}#" \
		"${PROTON_S}"/vkd3d-proton/vkd3d_build.h.in || die

	# DXVK's overlay looks for the OpenVR client library under this name
	for arch in x86_64 i386; do
		local triple=x86_64-w64-mingw32 outdir=win64 outname=libopenvr_api64.dll
		if [[ ${arch} == i386 ]]; then
			triple=i686-w64-mingw32 outdir=win32 outname=libopenvr_api.dll
		fi
		# the ELF flags of make.conf mean nothing to a PE link
		edo env -u CFLAGS -u CXXFLAGS -u CPPFLAGS -u LDFLAGS cmake -S "${PROTON_S}"/openvr -B "${WORKDIR}/build-openvr-${arch}" -G Ninja \
			-DCMAKE_SYSTEM_NAME=Windows \
			-DCMAKE_C_COMPILER=${triple}-clang \
			-DCMAKE_CXX_COMPILER=${triple}-clang++ \
			-DCMAKE_RC_COMPILER=${triple}-windres \
			-DBUILD_SHARED=ON -DUSE_LIBCXX=OFF -DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_C_FLAGS=-DWIN32 -DCMAKE_CXX_FLAGS="-O3 -march=native -DWIN32"
		edo env -u CFLAGS -u CXXFLAGS -u CPPFLAGS -u LDFLAGS ninja -C "${WORKDIR}/build-openvr-${arch}"
		mkdir -p "${WORKDIR}/components/lib/wine/dxvk/${arch}-windows" || die
		cp "${PROTON_S}/openvr/bin/${outdir}/${outname}" \
			"${WORKDIR}/components/lib/wine/dxvk/${arch}-windows/openvr_api_dxvk.dll" || die
	done

	_proton_wine_module lsteamclient lsteamclient
	_proton_wine_module steamexe steam_helper
	_proton_wine_module vrclient vrclient_x64
	_proton_wine_module umuexe umu_helper

	for arch in x86_64 i386; do
		_proton_meson_pe dxvk dxvk ${arch}
		_proton_meson_pe vkd3d-proton vkd3d-proton ${arch} \
			-Db_ndebug=true -Denable_extended_emulation=true
		_proton_meson_pe nvapi dxvk-nvapi ${arch}
	done
	_proton_meson_pe d7vk d7vk i386 \
		-Db_ndebug=true \
		-Denable_dxgi=false -Denable_d3d8=false -Denable_d3d10=false \
		-Denable_d3d11=false
}

# The tool as Steam wants it in compatibilitytools.d, from what has been
# installed: the same bin/ lib/wine/ share/wine/ tree under files/, Proton's
# launcher and its Python modules, and manifests which name no container, as
# there is no Steam Linux Runtime for the C library of this system.
_proton_install_dist() {
	local name=GE-Proton${PV/./-}-llvmlibc
	local dist=${WORKDIR}/dist/${name}
	local root=${ED}${WINE_PREFIX}
	local f

	mkdir -p "${dist}"/files || die
	cp -a "${root}"/{bin,lib,share} "${dist}"/files/ || die
	# the development half of Wine is of no use to a game
	rm -rf "${dist}"/files/share/man "${dist}"/files/share/applications || die
	( cd "${dist}"/files/bin && rm -f function_grep.pl widl winebuild winecpp \
		winedump winegcc wineg++ winemaker wmc wrc ) || die

	# make_wrapper's scripts are for the system install only
	find "${dist}"/files/bin -maxdepth 1 -name '*-${P}' -delete || die

	# fonts Proton would link into the prefix, from the system's
	mkdir -p "${dist}"/files/share/fonts || die
	cp "${EPREFIX}"/usr/share/fonts/liberation-fonts/*.ttf \
		"${dist}"/files/share/fonts/ || die

	for f in proton filelock.py vulkan.py utilities.py user_settings.sample.py \
			proton_3.7_tracked_files; do
		cp -a "${PROTON_S}/${f}" "${dist}/${f}" || die
	done
	cp -a "${PROTON_S}"/dist.LICENSE "${dist}"/LICENSE || die

	local pf=${PROTON_S}/protonfixes
	mkdir -p "${dist}"/protonfixes || die
	cp -r "${pf}"/gamefixes-* "${pf}"/verbs "${pf}"/*.py \
		"${pf}"/umu-database.csv "${dist}"/protonfixes/ || die
	rm -f "${dist}"/protonfixes/protonfixes_test.py

	cat > "${dist}"/toolmanifest.vdf <<-EOF || die
		"manifest"
		{
		  "version" "2"
		  "commandline" "/proton %verb%"
		  "use_sessions" "1"
		  "compatmanager_layer_name" "proton"
		}
	EOF
	sed -e "s|##BUILD_NAME##|${name}|" -e "s|##INTERNAL_TOOL_NAME##|${name}|" \
		"${PROTON_S}"/compatibilitytool.vdf.template \
		> "${dist}"/compatibilitytool.vdf || die
	echo "$(date +%s) ${GE_TAG}" > "${dist}"/version || die

	# the prefix new ones are copied from, made by the tree that is shipped
	# libsandbox links no libc, and wine-preloader has none for it to find, so
	# wine runs with the sandbox off
	WINEDLLOVERRIDES="mscoree,mshtml=" WINEDEBUG=-all \
		edo env -u LD_PRELOAD SANDBOX_ON=0 "${PYTHON}" "${PROTON_S}"/default_pfx.py \
		"${dist}"/files/share/default_pfx "${dist}"/files 0

	insinto /usr/share/${PN}
	local tarball=${T}/${name}.tar.zst
	tar -C "${WORKDIR}"/dist --owner=0 --group=0 -cf - "${name}" |
		zstd -T0 -19 -o "${tarball}" || die
	doins "${tarball}"
}

src_install() {
	WINE_PREFIX=/usr/lib/${P}
	local libwine=${WINE_PREFIX}/lib/wine

	emake DESTDIR="${D}" install
	[[ -e ${ED}${WINE_PREFIX}/bin/wine64 ]] ||
		dosym wine ${WINE_PREFIX}/bin/wine64

	# The loader runs a 64-bit child from the i386-unix directory, which is
	# where Proton puts the 64-bit loader for a 32-bit main binary.
	exeinto ${libwine}/i386-unix
	doexe "${ED}"${libwine}/x86_64-unix/wine64{,-preloader}

	insinto ${WINE_PREFIX}/lib
	doins -r "${WORKDIR}"/components/lib/wine

	insinto ${WINE_PREFIX}/share/openxr
	doins "${PROTON_S}"/wineopenxr/wineopenxr64.json

	local bin
	for bin in "${ED}"${WINE_PREFIX}/bin/*; do
		make_wrapper "${bin##*/}-${P}" "${bin#"${ED}"}"
	done

	dostrip -x ${libwine}/{x86_64,i386}-windows
	if use strip; then
		ebegin "Stripping Windows binaries"
		find "${ED}"${libwine}/*-windows -regex '.*\.\(a\|dll\|exe\)' \
			-type f -exec x86_64-w64-mingw32-strip --strip-unneeded {} +
		eend ${?} || die
	fi

	dodoc ANNOUNCE* AUTHORS README*

	_proton_install_dist
}
