# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/opengl/opengl-7.0.ebuild,v 1.16 2013/03/03 10:13:32 vapier Exp $

EAPI="5"

inherit multilib-minimal

DESCRIPTION="Virtual for OpenGL implementation"
HOMEPAGE=""
SRC_URI=""
LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="nine"
RDEPEND="|| ( media-libs/mesa[nine?,${MULTILIB_USEDEP}] media-libs/opengl-apple )"
DEPEND=""

src_unpack() {
	mkdir -p ${S}
}

src_prepare() {
	einfo "Skip prepare"
}

src_configure() {
	einfo "Skip configure"
}

src_compile() {
	einfo "Skip compile"
}

src_install() {
	einfo "Skip install"
}

