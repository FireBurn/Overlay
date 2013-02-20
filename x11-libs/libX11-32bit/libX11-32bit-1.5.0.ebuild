# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libX11/libX11-1.4.2.ebuild,v 1.2 2011/03/21 14:05:45 flameeyes Exp $

EAPI=5
ABI=x86
P="libX11-1.5.0"
PN="libX11"
S=${WORKDIR}/${P}

XORG_DOC=doc
inherit xorg-2 toolchain-funcs flag-o-matic

DESCRIPTION="X.Org X11 library"

KEYWORDS="~amd64"
IUSE="ipv6 test"

RDEPEND=">=x11-libs/libxcb-32bit-1.8.1
	x11-libs/xtrans
	>=x11-proto/xproto-7.0.17
	x11-proto/xf86bigfontproto
	x11-proto/inputproto
	x11-proto/kbproto
	x11-proto/xextproto
	app-emulation/emul-linux-x86-xlibs"
DEPEND="${RDEPEND}
	test? ( dev-lang/perl )"

PATCHES=(
	"${FILESDIR}"/${PN}-1.1.4-aix-pthread.patch
	"${FILESDIR}"/${PN}-1.1.5-winnt-private.patch
	"${FILESDIR}"/${PN}-1.1.5-solaris.patch
)

pkg_setup() {
	xorg-2_pkg_setup

	append-flags -m32

	XORG_CONFIGURE_OPTIONS=(
		$(use_with doc xmlto)
		$(use_enable doc specs)
		$(use_enable ipv6)
		--without-fop
	)
} 

src_configure() {
	[[ ${CHOST} == *-interix* ]] && export ac_cv_func_poll=no
	xorg-2_src_configure
}

src_compile() {
	# [Cross-Compile Love] Disable {C,LD}FLAGS and redefine CC= for 'makekeys'
	if tc-is-cross-compiler; then
		(
			filter-flags -m*
			emake -C "${AUTOTOOLS_BUILD_DIR}"/src/util CC=$(tc-getBUILD_CC) CFLAGS="${CFLAGS}" LDFLAGS="" clean all || die
		)
	fi
	xorg-2_src_compile
}

src_install() {
	autotools-utils_src_install \
		docdir="${EPREFIX}/usr/share/doc/${PF}"
	rm -rf "${D}"/usr/share || die "Removing man files failed."
	rm -rf "${D}"/usr/include || die "Removing include files failed."
}
