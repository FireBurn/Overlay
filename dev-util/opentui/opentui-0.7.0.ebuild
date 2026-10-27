# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ZIG_SLOT="0.16"

inherit zig

DESCRIPTION="Native Zig core of the OpenTUI terminal UI library"
HOMEPAGE="https://opentui.com/ https://github.com/anomalyco/opentui"
SRC_URI="https://github.com/anomalyco/opentui/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${P}/packages/native"

LICENSE="MIT"
# Bundled ghostty-vt, uucode, yoga, lcms2, stb (MIT), wuffs (Apache-2.0),
# libwebp (BSD), miniaudio
LICENSE+=" Apache-2.0 BSD || ( MIT-0 public-domain )"
SLOT="${PV}"
KEYWORDS="~amd64 ~arm64"
# elibc_llvm is not one of the values the gentoo profiles declare, so it is
# named here. On a profile which does not set ELIBC=llvm it is simply off.
IUSE="elibc_llvm"

src_unpack() {
	zig_src_unpack
	mkdir "${S}"/zig-deps || die
	tar -xzf "${S}"/src/vendor/zig-deps.tar.gz -C "${S}"/zig-deps || die
}

src_prepare() {
	zig_src_prepare

	# zig translate-c cannot expand llvm-libc's INTn_C, which pastes tokens
	if use elibc_llvm; then
		sed -E -i \
			-e 's/\bUINT(8|16|32|64)_C\(([^()]*)\)/((uint\1_t)\2)/g' \
			-e 's/\bINT(8|16|32|64)_C\(([^()]*)\)/((int\1_t)\2)/g' \
			include/opentui.h || die
	fi
}

src_configure() {
	local my_zbs_args=(
		--release=fast
		# Not the upstream glibc 2.17 target: link the system C library
		-Dlibrary-target=native
	)
	zig_src_configure
}

src_test() {
	:
}

src_install() {
	# build.zig installs to ../lib/<target> from the prefix
	exeinto /usr/$(get_libdir)/${P}
	doexe "${BUILD_DIR}"/lib/native/libopentui.so
}
