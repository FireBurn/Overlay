# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic meson

# Snapshot of Frida's Vala fork: upstream main plus the GLib-fork support,
# GLib.Source closure callbacks and libusb/libsoup bindings that frida-core
# relies on (its meson.build rejects any compiler whose version does not end
# in "-frida"). The commit is the one pinned in releng/deps.toml of the frida
# release. SLOT 0.58 is the API version this snapshot will become upstream.
COMMIT="fb982b3ccfb57bd9b6a833fc1653fbc6b0cd7b53"

DESCRIPTION="Compiler for the GObject type system (Frida's 0.58 snapshot)"
HOMEPAGE="https://vala.dev https://github.com/frida-forks/vala"
SRC_URI="https://github.com/frida-forks/vala/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/vala-${COMMIT}"

LICENSE="LGPL-2.1+"
SLOT="0.58"
KEYWORDS="~amd64 ~arm64"

RDEPEND=">=dev-libs/glib-2.48.0:2"
DEPEND="${RDEPEND}"
# Bootstrapped with the stable upstream release.
BDEPEND="
	dev-lang/vala:0.56
	app-alternatives/lex
	app-alternatives/yacc
	virtual/pkgconfig
"

src_configure() {
	export VALAC="${BROOT}/usr/bin/valac-0.56"

	# libvalacodegen lives in a private directory the loader does not search
	append-ldflags "-Wl,-rpath,${EPREFIX}/usr/$(get_libdir)/vala-0.58"

	meson_src_configure
}

src_install() {
	meson_src_install

	# Only the versioned names: the unversioned ones belong to the stable slot
	find "${ED}/usr/bin" -type l ! -name '*-0.58' -delete || die
	find "${ED}/usr/share/man" \( -type f -o -type l \) ! -name '*-0.58.1' -delete || die
	rm -rf "${ED}/usr/share/aclocal" "${ED}/usr/share/vala" || die
	find "${ED}" -name '*.la' -delete || die
}
