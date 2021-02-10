# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit meson multilib-minimal flag-o-matic

DESCRIPTION="A Vulkan-based translation layer for Direct3D 10/11"
HOMEPAGE="https://github.com/doitsujin/dxvk"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/doitsujin/dxvk.git"
	EGIT_BRANCH="master"
	inherit git-r3
	SRC_URI=""
else
	SRC_URI="https://github.com/doitsujin/dxvk/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64"
fi

LICENSE="ZLIB"
SLOT=0

IUSE="+d3d9 +d3d10 +d3d11 debug dxgi +mingw test winelib"
REQUIRED_USE="^^ ( mingw winelib )"

RESTRICT="test"

RDEPEND="
	|| (
		>=app-emulation/wine-vanilla-3.14:*[${MULTILIB_USEDEP},vulkan]
		>=app-emulation/wine-staging-3.14:*[${MULTILIB_USEDEP},vulkan]
		>=app-emulation/wine-d3d9-3.14:*[${MULTILIB_USEDEP},vulkan]
		>=app-emulation/wine-any-3.14:*[${MULTILIB_USEDEP},vulkan]
	)"
DEPEND="${RDEPEND}
	dev-util/glslang
	dev-util/vulkan-headers"

PATCHES=(
	"${FILESDIR}/flags.patch"
)

bits() { [[ ${ABI} = amd64 ]] && echo 64 || echo 32; }

dxvk_check_requirements() {
	if [[ ${MERGE_TYPE} != binary ]]; then
		if ! tc-is-gcc || [[ $(gcc-major-version) -lt 7 || $(gcc-major-version) -eq 7 && $(gcc-minor-version) -lt 3 ]]; then
			die "At least gcc 7.3 is required"
		fi
	fi

	if ! use abi_x86_64 && ! use abi_x86_32; then
		eerror "You need to enable at least one of abi_x86_32 and abi_x86_64."
		die
	fi

	if use mingw; then
		local -a categories
		use abi_x86_64 && categories+=("cross-x86_64-w64-mingw32")
		use abi_x86_32 && categories+=("cross-i686-w64-mingw32")

		for cat in ${categories[@]}; do
			local thread_model="$(LC_ALL=C ${cat/cross-/}-gcc -v 2>&1 \
				  | grep 'Thread model' | cut -d' ' -f3)"
			if ! has_version -b "${cat}/mingw64-runtime[libraries]" ||
					! has_version -b "${cat}/gcc" ||
					[[ "${thread_model}" != "posix" ]]; then
				eerror "The ${cat} toolchain is not properly installed."
				eerror "Make sure to install ${cat}/gcc with EXTRA_ECONF=\"--enable-threads=posix\""
				eerror "and ${cat}/mingw64-runtime with USE=\"libraries\"."
				elog "See <https://wiki.gentoo.org/wiki/Mingw> for more information."
				einfo "In short:"
				einfo "echo '~${cat}/mingw64-runtime-7.0.0 ~amd64' >> \\"
				einfo "    /etc/portage/package.accept_keywords/mingw"
				einfo "crossdev --stable --target ${cat}"
				einfo "echo 'EXTRA_ECONF=\"--enable-threads=posix\"' >> \\"
				einfo "    /etc/portage/env/mingw-gcc.conf"
				einfo "echo '${cat}/gcc mingw-gcc.conf' >> \\"
				einfo "    /etc/portage/package.env/mingw"
				einfo "echo '${cat}/mingw64-runtime libraries' >> \\"
				einfo "    /etc/portage/package.use/mingw"
				einfo "emerge --oneshot ${cat}/gcc ${cat}/mingw64-runtime"

				die "${cat} toolchain is not properly installed."
			fi
		done
	fi
}

pkg_pretend() {
	dxvk_check_requirements
}

pkg_setup() {
	dxvk_check_requirements
}

src_prepare() {
	default

	if use mingw; then
		local buildtype="win"
		filter-flags -Wl,--hash-style*
		eapply -R "${FILESDIR}/gcc-10.patch"
	else
		local buildtype="wine"
		filter-flags -flto*
	fi

	# Filter -march flags as this has been causing issues
	filter-flags "-march=*"

	# Create versioned setup script
	cp "setup_dxvk.sh" "dxvk-setup"
	sed -e "s#basedir=.*#basedir=\"${EPREFIX}/usr\"#" -i "dxvk-setup" || die

	bootstrap_dxvk() {
		# Set DXVK location for each ABI
		sed -e "s#x$(bits)#$(get_libdir)/dxvk#" -i "${S}/dxvk-setup" || die

		# Add *FLAGS to cross-file
		sed -i \
			-e "s!@CFLAGS@!$(_meson_env_array "${CFLAGS}")!" \
			-e "s!@CXXFLAGS@!$(_meson_env_array "${CXXFLAGS}")!" \
			-e "s!@LDFLAGS@!$(_meson_env_array "${LDFLAGS}")!" \
			build-${buildtype}$(bits).txt || die
	}

	multilib_foreach_abi bootstrap_dxvk

	# Clean missed ABI in setup script
	sed -e "s#.*x32.*##" -e "s#.*x64.*##" \
		-i "dxvk-setup" || die

	# Load configuration file from /etc/dxvk.conf.
	sed -Ei 's|filePath = "^(\s+)dxvk.conf";$|\1filePath = "/etc/dxvk.conf";|' \
		src/util/config/config.cpp || die
}

multilib_src_configure() {
	if use mingw; then
		local buildtype="win"
	else
		local buildtype="wine"
	fi

	local emesonargs=(
		--cross-file="${S}/build-${buildtype}$(bits).txt"
		--libdir="$(get_libdir)/dxvk"
		--bindir="$(get_libdir)/dxvk/bin"
		--buildtype="release"
		$(usex debug "" "--strip")
		$(meson_use d3d9 "enable_d3d9")
		$(meson_use d3d10 "enable_d3d10")
		$(meson_use d3d11 "enable_d3d11")
		$(meson_use dxgi "enable_dxgi")
		$(meson_use test "enable_tests")
	)
	meson_src_configure
}

multilib_src_install() {
	meson_src_install
}

multilib_src_install_all() {
	if use mingw; then
		find "${D}" -name '*.a' -delete -print
		if use abi_x86_32; then
			mv "${D}/usr/lib/dxvk/" "${D}/usr/lib/temp/"
			mv "${D}/usr/lib/temp/bin/" "${D}/usr/lib/dxvk/"
			rm -rf "${D}/usr/lib/temp/"
		fi
		if use abi_x86_64; then
			mv "${D}/usr/lib64/dxvk/" "${D}/usr/lib64/temp/"
			mv "${D}/usr/lib64/temp/bin/" "${D}/usr/lib64/dxvk/"
			rm -rf "${D}/usr/lib64/temp/"
		fi
	fi

	# create combined setup helper
	exeinto /usr/bin
	doexe "${S}/dxvk-setup"

	insinto etc
	doins "dxvk.conf"

	einstalldocs
}

pkg_postinst() {
	if use winelib; then
		ewarn "******************************************************************************"
		ewarn "*** Winelib builds of dxvk (like this one) are no longer supported upsteam ***"
		ewarn "***           Please do not file any issues upsteam                        ***"
		ewarn "*** Feel free to report them at https://github.com/FireBurn/Overlay/issues ***"
		ewarn "***               I'll try to help where I can                             ***"
		ewarn "******************************************************************************"
	fi
}
