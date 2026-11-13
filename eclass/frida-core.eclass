# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: frida-core.eclass
# @MAINTAINER:
# Mike Lothian <fireburn@gentoo.org>
# @SUPPORTED_EAPIS: 8
# @BLURB: Sources and build options shared by frida-core and its consumers
# @DESCRIPTION:
# frida-core pins every subproject by git revision and its build runs with
# downloads disabled, so each pin is a distfile of its own. This eclass holds
# the pins of one frida-core release, unpacks them into a tree, and carries
# the meson options that make the tree build offline against bundled copies of
# glib and capstone. Bump FRIDA_CORE_PV together with the pins, which are
# regenerated from the wrap files of the release.

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_FRIDA_CORE_ECLASS} ]]; then
_FRIDA_CORE_ECLASS=1

inherit flag-o-matic toolchain-funcs

# @ECLASS_VARIABLE: FRIDA_CORE_PV
# @DESCRIPTION:
# The frida-core release that the pins below belong to.
FRIDA_CORE_PV=17.26.3

# @ECLASS_VARIABLE: FRIDA_CORE_SRC_URI
# @DESCRIPTION:
# The frida-core release tarball and every pinned subproject.
FRIDA_CORE_SRC_URI="
	https://github.com/frida/frida-core/archive/refs/tags/${FRIDA_CORE_PV}.tar.gz -> frida-core-${FRIDA_CORE_PV}.tar.gz
	https://github.com/frida/efni/archive/4fdc5f4c0d7ec4086362961150a80a92bc6e4b72.tar.gz -> frida-efni-4fdc5f4c0d7ec4086362961150a80a92bc6e4b72.tar.gz
	https://github.com/frida/frida-gum/archive/refs/tags/17.26.3.tar.gz -> frida-frida-gum-17.26.3.tar.gz
	https://github.com/frida-forks/capstone/archive/f919a03a5417e1c7ea3af7035225073437030ef2.tar.gz -> frida-forks-capstone-f919a03a5417e1c7ea3af7035225073437030ef2.tar.gz
	https://github.com/frida-forks/json-glib/archive/0242c39f1f60f844c9df41e83434251b06609e82.tar.gz -> frida-forks-json-glib-0242c39f1f60f844c9df41e83434251b06609e82.tar.gz
	https://github.com/frida-forks/libdwarf/archive/9ac8cc22cab54d72cb355a44e85db716a7006f47.tar.gz -> frida-forks-libdwarf-9ac8cc22cab54d72cb355a44e85db716a7006f47.tar.gz
	https://github.com/frida-forks/libsoup/archive/2537f36926436ef7ac7e2430c25755216ed54ca5.tar.gz -> frida-forks-libsoup-2537f36926436ef7ac7e2430c25755216ed54ca5.tar.gz
	https://github.com/frida-forks/libunwind/archive/61860c614cded2a09ff48c8dee569c4179e33697.tar.gz -> frida-forks-libunwind-61860c614cded2a09ff48c8dee569c4179e33697.tar.gz
	https://github.com/frida-forks/quickjs/archive/6f3b5b4827d4c81af85627d66fce2ec3c8ab70d0.tar.gz -> frida-forks-quickjs-6f3b5b4827d4c81af85627d66fce2ec3c8ab70d0.tar.gz
	https://github.com/frida-forks/tinycc/archive/c0b84021e3e5c8359a469b1af2bf4abd83a7a26a.tar.gz -> frida-forks-tinycc-c0b84021e3e5c8359a469b1af2bf4abd83a7a26a.tar.gz
	https://github.com/frida-forks/glib/archive/c6df0665dab0f971f66c5c46055b7d0b6085d1b1.tar.gz -> frida-forks-glib-c6df0665dab0f971f66c5c46055b7d0b6085d1b1.tar.gz
	https://gitlab.gnome.org/GNOME/gvdb/-/archive/2b42fc75f09dbe1cd1057580b5782b08f2dcb400/gvdb-2b42fc75f09dbe1cd1057580b5782b08f2dcb400.tar.gz -> gnome-gvdb-2b42fc75f09dbe1cd1057580b5782b08f2dcb400.tar.gz
	https://github.com/frida-forks/libbpf/archive/9c4e176810717e27b6990a8722b252fc1967667f.tar.gz -> frida-forks-libbpf-9c4e176810717e27b6990a8722b252fc1967667f.tar.gz
	https://github.com/frida-forks/libgee/archive/69621d2c665b75c1e064abdecd540ef1749615ee.tar.gz -> frida-forks-libgee-69621d2c665b75c1e064abdecd540ef1749615ee.tar.gz
	https://github.com/frida/releng/archive/fe7d31dfbcfe34701851411773cf82c0359b44bd.tar.gz -> frida-releng-fe7d31dfbcfe34701851411773cf82c0359b44bd.tar.gz
	https://github.com/frida-forks/meson/archive/145667c57ed2649ddcc6fbb11b6008e0d451df1d.tar.gz -> frida-forks-meson-145667c57ed2649ddcc6fbb11b6008e0d451df1d.tar.gz
	https://github.com/python-poetry/tomlkit/archive/911cccd630965ff423316e25b4685ecf7df0ec0a.tar.gz -> python-poetry-tomlkit-911cccd630965ff423316e25b4685ecf7df0ec0a.tar.gz
"

# @ECLASS_VARIABLE: FRIDA_CORE_FILESDIR
# @DESCRIPTION:
# Directory holding the patches that frida-core needs.
FRIDA_CORE_FILESDIR=${EBUILD%/*/*/*}/dev-libs/frida-core/files

# @ECLASS_VARIABLE: FRIDA_CORE_PATCHES
# @DESCRIPTION:
# Patches to apply to the unpacked tree, in order, relative to its root.
FRIDA_CORE_PATCHES=(
	"${FRIDA_CORE_FILESDIR}"/libunwind-include-immintrin-for-shstk.patch
	"${FRIDA_CORE_FILESDIR}"/gum-pthread-from-ptr-integer-pthread_t.patch
	"${FRIDA_CORE_FILESDIR}"/gum-module-handle-llvm-libc-uses-dlopen.patch
	"${FRIDA_CORE_FILESDIR}"/libc-shim-stdio-streams-not-const.patch
	"${FRIDA_CORE_FILESDIR}"/libc-shim-keep-out-of-gcc-lto.patch
)

# @ECLASS_VARIABLE: FRIDA_CORE_DEPEND
# @DESCRIPTION:
# Libraries that the bundled build still takes from the system.
FRIDA_CORE_DEPEND="
	app-arch/brotli
	app-arch/xz-utils
	dev-libs/elfutils
	dev-libs/libffi
	dev-libs/libpcre2
	dev-libs/openssl:=
	dev-db/sqlite
	net-libs/libpsl
	net-libs/nghttp2:=
	virtual/zlib:=
"

# @ECLASS_VARIABLE: FRIDA_CORE_BDEPEND
# @DESCRIPTION:
# Build tools that the tree needs.
FRIDA_CORE_BDEPEND="
	dev-lang/vala:0.58
	virtual/pkgconfig
"

# <directory inside the tree> <distfile>
_FRIDA_PINS=(
	"subprojects/efni frida-efni-4fdc5f4c0d7ec4086362961150a80a92bc6e4b72.tar.gz"
	"subprojects/frida-gum frida-frida-gum-17.26.3.tar.gz"
	"subprojects/frida-gum/subprojects/capstone frida-forks-capstone-f919a03a5417e1c7ea3af7035225073437030ef2.tar.gz"
	"subprojects/frida-gum/subprojects/json-glib frida-forks-json-glib-0242c39f1f60f844c9df41e83434251b06609e82.tar.gz"
	"subprojects/frida-gum/subprojects/libdwarf frida-forks-libdwarf-9ac8cc22cab54d72cb355a44e85db716a7006f47.tar.gz"
	"subprojects/frida-gum/subprojects/libsoup frida-forks-libsoup-2537f36926436ef7ac7e2430c25755216ed54ca5.tar.gz"
	"subprojects/frida-gum/subprojects/libunwind frida-forks-libunwind-61860c614cded2a09ff48c8dee569c4179e33697.tar.gz"
	"subprojects/frida-gum/subprojects/quickjs frida-forks-quickjs-6f3b5b4827d4c81af85627d66fce2ec3c8ab70d0.tar.gz"
	"subprojects/frida-gum/subprojects/tinycc frida-forks-tinycc-c0b84021e3e5c8359a469b1af2bf4abd83a7a26a.tar.gz"
	"subprojects/glib frida-forks-glib-c6df0665dab0f971f66c5c46055b7d0b6085d1b1.tar.gz"
	"subprojects/glib/subprojects/gvdb gnome-gvdb-2b42fc75f09dbe1cd1057580b5782b08f2dcb400.tar.gz"
	"subprojects/libbpf frida-forks-libbpf-9c4e176810717e27b6990a8722b252fc1967667f.tar.gz"
	"subprojects/libgee frida-forks-libgee-69621d2c665b75c1e064abdecd540ef1749615ee.tar.gz"
	"releng frida-releng-fe7d31dfbcfe34701851411773cf82c0359b44bd.tar.gz"
	"releng/meson frida-forks-meson-145667c57ed2649ddcc6fbb11b6008e0d451df1d.tar.gz"
	"releng/tomlkit python-poetry-tomlkit-911cccd630965ff423316e25b4685ecf7df0ec0a.tar.gz"
)

# @FUNCTION: frida-core_unpack
# @USAGE: <destination>
# @DESCRIPTION:
# Unpack the frida-core release into the destination directory and put every
# pinned subproject in its place.
frida-core_unpack() {
	local dest=$1 i dir dist
	mkdir -p "${dest}" || die
	tar -xzf "${DISTDIR}/frida-core-${FRIDA_CORE_PV}.tar.gz" -C "${dest}" \
		--strip-components=1 || die "unpacking frida-core"

	for ((i = 0; i < ${#_FRIDA_PINS[@]}; i++)); do
		set -- ${_FRIDA_PINS[i]}
		dir=${dest}/$1 dist=$2
		rm -rf "${dir}" || die
		mkdir -p "${dir}" || die
		tar -xzf "${DISTDIR}/${dist}" -C "${dir}" --strip-components=1 \
			|| die "unpacking ${dist}"
	done
}

# @FUNCTION: frida-core_patch
# @USAGE: <tree>
# @DESCRIPTION:
# Apply the frida-core patches to a tree made by frida-core_unpack.
frida-core_patch() {
	pushd "$1" >/dev/null || die
	eapply "${FRIDA_CORE_PATCHES[@]}"
	popd >/dev/null || die
}

# @FUNCTION: frida-core_setup_env
# @DESCRIPTION:
# Environment for the build. The devkit is made by objcopy and ar over every
# object in the tree, and neither reads LTO bitcode, so objects carry native
# code next to the bitcode; the final link still runs LTO.
frida-core_setup_env() {
	# meson.eclass tells LTO from a plain object by its bitcode, which a fat
	# object is not, so this has to be asked before the flag is added.
	_FRIDA_CORE_LTO=
	tc-is-lto && _FRIDA_CORE_LTO=1

	append-flags -ffat-lto-objects

	# Assembly in the bundled libraries carries no .note.GNU-stack, which makes
	# the linker ask for an executable stack and glibc refuse to load the module.
	append-ldflags -Wl,-z,noexecstack

	# The agent replaces stdio with its own streams. Fortified calls such as
	# __fprintf_chk are not part of that, and glibc aborts on a foreign FILE.
	append-cppflags -U_FORTIFY_SOURCE

	export FRIDA_VERSION=${FRIDA_CORE_PV}
	export VALAC=${BROOT}/usr/bin/valac-0.58
}

# @FUNCTION: frida-core_emesonargs
# @USAGE: <prefix>
# @DESCRIPTION:
# Fill FRIDA_CORE_EMESONARGS with the meson options for frida-core. The prefix
# is empty when frida-core is the project and "frida-core:" when it is a
# subproject. The bundled glib and capstone replace the system ones: the
# system capstone declares bpf_insn as an enum, which libbpf redefines.
frida-core_emesonargs() {
	local p=$1
	FRIDA_CORE_EMESONARGS=(
		-Ddefault_library=static
		-D${p}fruity_backend=disabled
		-D${p}droidy_backend=enabled
		-D${p}simmy_backend=disabled
		-D${p}barebone_backend=disabled
		-D${p}connectivity=disabled
		-D${p}portal=disabled
		-D${p}gadget=disabled
		-D${p}inject=disabled
		-D${p}server=disabled
		-D${p}compat=disabled
		-D${p}devkits=core
		-D${p}tests=disabled
		-D${p}compiler_backend=disabled
		-Dfrida-gum:v8=disabled
		-Dfrida-gum:quickjs=enabled
		-Dfrida-gum:database=disabled
		-Dfrida-gum:gumpp=disabled
		-Dfrida-gum:tests=disabled
		-Dglib:introspection=disabled
	)

	if [[ -n ${_FRIDA_CORE_LTO} ]]; then
		local v=$(get-flag flto)
		FRIDA_CORE_EMESONARGS+=( -Db_lto=true )
		case ${v} in
			thin) FRIDA_CORE_EMESONARGS+=( -Db_lto_mode=thin ) ;;
			''|*[!0-9]*) ;;
			*) FRIDA_CORE_EMESONARGS+=( -Db_lto_threads=${v} ) ;;
		esac
	fi
}

fi

