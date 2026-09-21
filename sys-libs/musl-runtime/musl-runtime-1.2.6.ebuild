# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/musl.asc
inherit flag-o-matic toolchain-funcs verify-sig

MY_P="musl-${PV}"

DESCRIPTION="musl's loader and shared libc under /opt/musl, for foreign binaries"
HOMEPAGE="https://musl.libc.org"
SRC_URI="
	https://musl.libc.org/releases/${MY_P}.tar.gz
	verify-sig? ( https://musl.libc.org/releases/${MY_P}.tar.gz.asc )
"
S="${WORKDIR}/${MY_P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="verify-sig? ( sec-keys/openpgp-keys-musl )"

MUSL_PREFIX="/opt/musl"

QA_SONAME="opt/musl/lib/libc.so"
QA_DT_NEEDED="opt/musl/lib/libc.so"
QA_FLAGS_IGNORED="opt/musl/lib/libc.so"

src_configure() {
	# musl is built with its own headers and start files throughout, so
	# nothing here comes from the libc this system actually runs.
	strip-flags
	filter-lto
	./configure \
		--prefix="${EPREFIX}${MUSL_PREFIX}" \
		--syslibdir="${EPREFIX}${MUSL_PREFIX}/lib" \
		--disable-static \
		--disable-gcc-wrapper \
		CC="$(tc-getCC)" || die
}

src_install() {
	emake DESTDIR="${D}" install

	# Headers and start files belong to the system libc. Leaving musl's
	# where a compiler could reach them would be an invitation to link
	# something against the wrong one.
	rm -r "${ED}${MUSL_PREFIX}"/include || die
	rm -f "${ED}${MUSL_PREFIX}"/lib/*.a "${ED}${MUSL_PREFIX}"/lib/*.o || die

	[[ -e ${ED}${MUSL_PREFIX}/lib/ld-musl-x86_64.so.1 ]] ||
		dosym libc.so "${MUSL_PREFIX}"/lib/ld-musl-x86_64.so.1

	# The name Alpine gives the library, which is what binaries built there
	# record in DT_NEEDED.
	dosym ld-musl-x86_64.so.1 "${MUSL_PREFIX}"/lib/libc.musl-x86_64.so.1
}
