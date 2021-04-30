# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit meson multilib-minimal flag-o-matic

DESCRIPTION="A Vulkan-based translation layer for Direct3D 10/11"
HOMEPAGE="https://github.com/doitsujin/vkd3d"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/HansKristian-Work/vkd3d-proton.git"
	EGIT_BRANCH="master"
	inherit git-r3
	SRC_URI=""
	KEYWORDS="-* ~amd64"
else
	SRC_URI="https://github.com/HansKristian-Work/vkd3d-proton/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64"
fi

LICENSE="ZLIB"
SLOT=0

IUSE="debug test"

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
	dev-util/spirv-headers
	dev-util/vulkan-headers"

PATCHES=(
	"${FILESDIR}/flags.patch"
)

bits() { [[ ${ABI} = amd64 ]] && echo 64 || echo 32; }
altbits() { [[ ${ABI} = amd64 ]] && echo 64 || echo 86; }

vkd3d_check_requirements() {
	if [[ ${MERGE_TYPE} != binary ]]; then
		if ! tc-is-gcc || [[ $(gcc-major-version) -lt 7 || $(gcc-major-version) -eq 7 && $(gcc-minor-version) -lt 3 ]]; then
			die "At least gcc 7.3 is required"
		fi
	fi

	if ! use abi_x86_64 && ! use abi_x86_32; then
		eerror "You need to enable at least one of abi_x86_32 and abi_x86_64."
		die
	fi

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
}

pkg_pretend() {
	vkd3d_check_requirements
}

pkg_setup() {
	vkd3d_check_requirements
}

src_prepare() {
	default

	filter-flags -Wl,--hash-style*

	# Create versioned setup script
	cp "setup_vkd3d_proton.sh" "vkd3d-setup"
	sed -e "s#basedir=.*#basedir=\"${EPREFIX}/usr\"#" -i "vkd3d-setup" || die

	bootstrap_vkd3d() {
		# Set DXVK location for each ABI
		sed -e "s#x$(altbits)#$(get_libdir)/vkd3d#" -i "${S}/vkd3d-setup" || die

		# Add *FLAGS to cross-file
		sed -i \
			-e "s!@CFLAGS@!$(_meson_env_array "${CFLAGS}")!" \
			-e "s!@CXXFLAGS@!$(_meson_env_array "${CXXFLAGS}")!" \
			-e "s!@LDFLAGS@!$(_meson_env_array "${LDFLAGS}")!" \
			build-win$(bits).txt || die
	}

	multilib_foreach_abi bootstrap_vkd3d

	# Clean missed ABI in setup script
	sed -e "s#.*x32.*##" -e "s#.*x64.*##" \
		-i "vkd3d-setup" || die
}

multilib_src_configure() {
	local emesonargs=(
		--cross-file="${S}/build-win$(bits).txt"
		--libdir="$(get_libdir)/vkd3d"
		--bindir="$(get_libdir)/vkd3d/bin"
		--buildtype="release"
		$(usex debug "" "--strip")
		$(meson_use test "enable_tests")
	)
	meson_src_configure
}

multilib_src_install() {
	meson_src_install
}

multilib_src_install_all() {
	find "${D}" -name '*.a' -delete -print
	if use abi_x86_32; then
		mv "${D}/usr/lib/vkd3d/" "${D}/usr/lib/temp/"
		mv "${D}/usr/lib/temp/bin/" "${D}/usr/lib/vkd3d/"
		rm -rf "${D}/usr/lib/temp/"
	fi
	if use abi_x86_64; then
		mv "${D}/usr/lib64/vkd3d/" "${D}/usr/lib64/temp/"
		mv "${D}/usr/lib64/temp/bin/" "${D}/usr/lib64/vkd3d/"
		rm -rf "${D}/usr/lib64/temp/"
	fi

	# create combined setup helper
	exeinto /usr/bin
	doexe "${S}/vkd3d-setup"

	einstalldocs
}
