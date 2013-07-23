# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-baselibs/emul-linux-x86-baselibs-20120520.ebuild,v 1.1 2012/05/20 12:57:13 pacho Exp $

EAPI=5

inherit emul-linux-x86

LICENSE="Artistic GPL-1 GPL-2 GPL-3 BSD BSD-2 BZIP2 AFL-2.1 LGPL-2.1 BSD-4 MIT public-domain
LGPL-3 LGPL-2 GPL-2-with-exceptions MPL-1.1 OPENLDAP UoI-NCSA ZLIB openssl tcp_wrappers_license"

IUSE="abi_x86_32"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="!<app-emulation/emul-linux-x86-medialibs-10.2" # bug 168507
PDEPEND="dev-libs/glib[abi_x86_32(-)?]"

QA_DT_HASH="usr/lib32/.*"

PYTHON_UPDATER_IGNORE="1"

src_prepare() {
	export ALLOWED="(${S}/lib32/security/pam_filter/upperLOWER|${S}/etc/env.d|${S}/lib32/security/pam_ldap.so)"
	emul-linux-x86_src_prepare
	if use abi_x86_32 ; then
		rm -rf "${S}/etc/env.d/binutils/" \
				"${S}/usr/i686-pc-linux-gnu/lib" \
				"${S}/usr/lib32/engines/" \
				"${S}/usr/lib32/openldap/" || die
		rm -rf "${S}/usr/lib32/llvm/" || die
		rm -rf "${S}/usr/lib32/glib-2.0/include/glibconfig.h" || die
		rm -rf "${S}/usr/lib32/libgio-2.0.so" || die
		rm -rf "${S}/usr/lib32/libgio-2.0.so.0" || die
		rm -rf "${S}/usr/lib32/libgio-2.0.so.0.3200.4" || die
		rm -rf "${S}/usr/lib32/libglib-2.0.so" || die
		rm -rf "${S}/usr/lib32/libglib-2.0.so.0" || die
		rm -rf "${S}/usr/lib32/libglib-2.0.so.0.3200.4" || die
		rm -rf "${S}/usr/lib32/libgmodule-2.0.so" || die
		rm -rf "${S}/usr/lib32/libgmodule-2.0.so.0" || die
		rm -rf "${S}/usr/lib32/libgmodule-2.0.so.0.3200.4" || die
		rm -rf "${S}/usr/lib32/libgobject-2.0.so" || die
		rm -rf "${S}/usr/lib32/libgobject-2.0.so.0" || die
		rm -rf "${S}/usr/lib32/libgobject-2.0.so.0.3200.4" || die
		rm -rf "${S}/usr/lib32/libgthread-2.0.so" || die
		rm -rf "${S}/usr/lib32/libgthread-2.0.so.0" || die
		rm -rf "${S}/usr/lib32/libgthread-2.0.so.0.3200.4" || die
		rm -rf "${S}/usr/lib32/pkgconfig/gio-2.0.pc" || die
		rm -rf "${S}/usr/lib32/pkgconfig/gio-unix-2.0.pc" || die
		rm -rf "${S}/usr/lib32/pkgconfig/glib-2.0.pc" || die
		rm -rf "${S}/usr/lib32/pkgconfig/gmodule-2.0.pc" || die
		rm -rf "${S}/usr/lib32/pkgconfig/gmodule-export-2.0.pc" || die
		rm -rf "${S}/usr/lib32/pkgconfig/gmodule-no-export-2.0.pc" || die
		rm -rf "${S}/usr/lib32/pkgconfig/gobject-2.0.pc" || die
		rm -rf "${S}/usr/lib32/pkgconfig/gthread-2.0.pc" || die
	fi
	ln -s ../share/terminfo "${S}/usr/lib32/terminfo" || die
}
