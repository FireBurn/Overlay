# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="glibc's library names and internals on top of llvm-libc, for glibc programs"
HOMEPAGE="https://libc.llvm.org/"
S="${WORKDIR}"

LICENSE="Apache-2.0-with-LLVM-exceptions"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="llvm-runtimes/libc"
DEPEND="${RDEPEND}"

# The names glibc split out of libc.so.6 and kept as empty libraries
EMPTY_LIBS=( libdl.so.2 libpthread.so.0 librt.so.1 libm.so.6 libutil.so.1 )

src_compile() {
	# libc.so.1 and libm.so.1 are needed whether or not the shim itself
	# references them, since they are what a name falls through to.
	$(tc-getCC) ${CFLAGS} ${LDFLAGS} -shared -fPIC \
		-Wl,-soname,libc.so.6 -o libc.so.6 "${FILESDIR}"/glibc-abi.c \
		-Wl,--no-as-needed -lc -lm -Wl,--as-needed || die

	local lib
	echo "" > empty.c || die
	for lib in "${EMPTY_LIBS[@]}"; do
		$(tc-getCC) ${CFLAGS} ${LDFLAGS} -shared -fPIC \
			-Wl,-soname,${lib} -o ${lib} empty.c \
			-L. -Wl,--no-as-needed -l:libc.so.6 -Wl,--as-needed || die
	done
}

src_install() {
	into /
	dolib.so libc.so.6

	local lib
	for lib in "${EMPTY_LIBS[@]}"; do
		dolib.so ${lib}
	done
}
