# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/emul-linux-x86-baselibs/emul-linux-x86-baselibs-20120520.ebuild,v 1.1 2012/05/20 12:57:13 pacho Exp $

EAPI="4"

inherit emul-linux-x86

LICENSE="Artistic GPL-1 GPL-2 GPL-3 BSD BSD-2 BZIP2 AFL-2.1 LGPL-2.1 BSD-4 MIT public-domain
LGPL-3 LGPL-2 GPL-2-with-exceptions MPL-1.1 OPENLDAP OracleDB UoI-NCSA ZLIB as-is openssl tcp_wrappers_license"

KEYWORDS="-* ~amd64"

DEPEND=""
RDEPEND="!<app-emulation/emul-linux-x86-medialibs-10.2" # bug 168507

QA_DT_HASH="usr/lib32/.*"

PYTHON_UPDATER_IGNORE="1"

src_prepare() {
	export ALLOWED="(${S}/lib32/security/pam_filter/upperLOWER|${S}/etc/env.d|${S}/lib32/security/pam_ldap.so)"
	emul-linux-x86_src_prepare
	rm -rf "${S}/etc/env.d/binutils/" \
			"${S}/usr/i686-pc-linux-gnu/lib" \
			"${S}/usr/lib32/engines/" \
			"${S}/usr/lib32/openldap/" || die
	rm -rf "${S}/usr/lib32/llvm/" || die
	ln -s ../share/terminfo "${S}/usr/lib32/terminfo" || die
}
