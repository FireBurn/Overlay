# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic meson

# Frida's Vala fork. frida-core refuses to configure with any other compiler
# (its version must end in "-frida"): the fork carries GLib-fork support, GLib.Source
# closure callbacks and extra libusb/libsoup bindings that are not upstream.
# The commit is the one pinned in releng/deps.toml of the frida release.
COMMIT="fb982b3ccfb57bd9b6a833fc1653fbc6b0cd7b53"

DESCRIPTION="Frida's fork of the Vala compiler, needed to build frida-core"
HOMEPAGE="https://github.com/frida-forks/vala"
SRC_URI="https://github.com/frida-forks/vala/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/vala-${COMMIT}"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND=">=dev-libs/glib-2.48.0:2"
DEPEND="${RDEPEND}"
# Bootstrapped with any installed upstream Vala.
BDEPEND="
	dev-lang/vala
	app-alternatives/lex
	app-alternatives/yacc
	virtual/pkgconfig
"

# Kept out of /usr so that it cannot clash with an upstream vala or
# vala-common; frida-core is pointed at it with VALAC.
FRIDA_VALA_PREFIX="${EPREFIX}/usr/lib/${PN}"

src_configure() {
	local valac=$(ls "${BROOT}"/usr/bin/valac-* 2>/dev/null | sort -V | tail -n1)
	[[ -x ${valac} ]] || die "no upstream valac found to bootstrap with"
	export VALAC=${valac}

	local libdir=${FRIDA_VALA_PREFIX}/$(get_libdir)
	append-ldflags "-Wl,-rpath,${libdir}:${libdir}/vala-0.58"

	local emesonargs=(
		--prefix="${FRIDA_VALA_PREFIX}"
		--libdir="${libdir}"
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	find "${ED}" -name '*.la' -delete || die
}
