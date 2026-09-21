# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="musl's ABI on top of llvm-libc, for running musl binaries unmodified"
HOMEPAGE="https://libc.llvm.org/"
S="${WORKDIR}"

LICENSE="Apache-2.0-with-LLVM-exceptions MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="llvm-runtimes/libc"
DEPEND="${RDEPEND}"

SONAME="libc.musl-x86_64.so.1"
LOADER="ld-llvm-libc-x86_64.so.1"

src_compile() {
	# Resolution runs from the program to this library and on to the ones
	# it needs, so a name defined here takes the place of libc's and a name
	# left out reaches libc untouched. musl keeps the maths in libc, so
	# libm has to be pulled in here for those names to be reachable too.
	$(tc-getCC) ${CFLAGS} ${LDFLAGS} -shared -fPIC \
		-Wl,-soname,"${SONAME}" \
		-o "${SONAME}" \
		"${FILESDIR}"/musl-abi.c "${FILESDIR}"/musl-setjmp.S \
		-lm || die
}

src_install() {
	into /
	dolib.so "${SONAME}"

	# The interpreter a musl binary names. It is this libc's loader, which
	# is what reads the program headers, lays out thread local storage and
	# binds the symbols.
	dosym "${LOADER}" /$(get_libdir)/ld-musl-x86_64.so.1
}

pkg_postinst() {
	elog "musl binaries run unmodified: the loader is llvm-libc's and the"
	elog "libc behind it is llvm-libc. Nothing of musl is installed."
}
